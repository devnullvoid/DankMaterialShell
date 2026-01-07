.pragma library
// This exists only beacause I haven't been able to get linkColor to work with MarkdownText
// May not be necessary if that's possible tbh.
function markdownToHtml(text) {
    if (!text) return "";

    // Store code blocks and inline code to protect them from further processing
    const codeBlocks = [];
    const inlineCode = [];
    const protectedBlocks = [];
    let blockIndex = 0;
    let inlineIndex = 0;
    let protectedIndex = 0;

    // First, extract and replace code blocks with placeholders
    let html = text.replace(/```([\s\S]*?)```/g, (match, code) => {
        // Trim leading and trailing blank lines only
        const trimmedCode = code.replace(/^\n+|\n+$/g, '');
        // Escape HTML entities in code
        const escapedCode = trimmedCode.replace(/&/g, '&amp;')
                                       .replace(/</g, '&lt;')
                                       .replace(/>/g, '&gt;');
        codeBlocks.push(`<pre><code>${escapedCode}</code></pre>`);
        return `\x00CODEBLOCK${blockIndex++}\x00`;
    });

    // Extract and replace inline code
    html = html.replace(/`([^`]+)`/g, (match, code) => {
        // Escape HTML entities in code
        const escapedCode = code.replace(/&/g, '&amp;')
                               .replace(/</g, '&lt;')
                               .replace(/>/g, '&gt;');
        // Use span with background color for highlighting. #30FFFFFF is ~19% white, good for dark themes.
        inlineCode.push(`<span style="font-family: monospace; background-color: #30FFFFFF;">&nbsp;${escapedCode}&nbsp;</span>`);
        return `\x00INLINECODE${inlineIndex++}\x00`;
    });

    // Now process everything else
    // Escape HTML entities (but not in code blocks)
    html = html.replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;');

    // Headers
    html = html.replace(/^### (.*?)$/gm, '<h3><font size="4">$1</font></h3>');
    html = html.replace(/^## (.*?)$/gm, '<h2><font size="5">$1</font></h2>');
    html = html.replace(/^# (.*?)$/gm, '<h1><font size="6">$1</font></h1>');

    // Bold and italic (order matters!)
    html = html.replace(/\*\*\*(.*?)\*\*\*/g, '<b><i>$1</i></b>');
    html = html.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>');
    html = html.replace(/\*(.*?)\*/g, '<i>$1</i>');
    html = html.replace(/___(.*?)___/g, '<b><i>$1</i></b>');
    html = html.replace(/__(.*?)__/g, '<b>$1</b>');
    html = html.replace(/_(.*?)_/g, '<i>$1</i>');

    // Links
    html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');

    // Lists - Differentiate UL and OL
    // Replace * - with <li_ul>
    html = html.replace(/^\s*[\*\-] (.*?)$/gm, '<li_ul>$1</li_ul>');
    // Replace 1. with <li_ol>
    html = html.replace(/^\s*\d+\. (.*?)$/gm, '<li_ol>$1</li_ol>');

    // Wrap consecutive list items and EXTRACT them to protect from newline processing
    // Unordered
    html = html.replace(/(<li_ul>[\s\S]*?<\/li_ul>\s*)+/g, function(match) {
        // Strip newlines inside the list block to avoid double spacing later
        const content = match.replace(/<\/?li_ul>/g, (tag) => tag.replace('li_ul', 'li')).replace(/\n/g, '');
        const block = `<ul>${content}</ul>`;
        protectedBlocks.push(block);
        return `\x00PROTECTEDBLOCK${protectedIndex++}\x00\n`;
    });

    // Ordered
    html = html.replace(/(<li_ol>[\s\S]*?<\/li_ol>\s*)+/g, function(match) {
        const content = match.replace(/<\/?li_ol>/g, (tag) => tag.replace('li_ol', 'li')).replace(/\n/g, '');
        const block = `<ol>${content}</ol>`;
        protectedBlocks.push(block);
        return `\x00PROTECTEDBLOCK${protectedIndex++}\x00\n`;
    });

    // Blockquotes
    // Note: '>' is already escaped to '&gt;'
    html = html.replace(/^&gt; (.*?)$/gm, '<bq_line>$1</bq_line>');
    html = html.replace(/(<bq_line>[\s\S]*?<\/bq_line>\s*)+/g, function(match) {
        // Merge content, replacing closing/opening tags with BR
        // <bq_line>A</bq_line>\n<bq_line>B</bq_line> -> A<br/>B
        const inner = match.replace(/<\/bq_line>\s*<bq_line>/g, '<br/>')
                           .replace(/<bq_line>/g, '')
                           .replace(/<\/bq_line>/g, '')
                           .trim();
        // Use blockquote tag (supported by QML for indentation) and add styling
        const block = `<blockquote><font color="#a0a0a0"><i>${inner}</i></font></blockquote>`;
        protectedBlocks.push(block);
        return `\x00PROTECTEDBLOCK${protectedIndex++}\x00\n`;
    });

    // Detect plain URLs and wrap them in anchor tags (but not inside existing <a> or markdown links)
    html = html.replace(/(^|[^"'>])((https?|file):\/\/[^\s<]+)/g, '$1<a href="$2">$2</a>');

    // Restore code blocks and inline code BEFORE line break processing
    // (We want newlines in code blocks to become <br> or handled by pre?)
    // Actually, QML Text <pre> handles \n correctly?
    // If we let \n become <br>, it might be double spacing in pre.
    // Let's protect code blocks too if we suspect issues, but previously it was fine.
    // Actually, let's keep code blocks as they were, handled before line breaks.
    html = html.replace(/\x00CODEBLOCK(\d+)\x00/g, (match, index) => {
        return codeBlocks[parseInt(index)];
    });

    html = html.replace(/\x00INLINECODE(\d+)\x00/g, (match, index) => {
        return inlineCode[parseInt(index)];
    });

    // Line breaks (after code blocks are restored)
    html = html.replace(/\n\n/g, '</p><p>');
    html = html.replace(/\n/g, '<br/>');

    // Wrap in paragraph tags if not already wrapped
    if (!html.startsWith('<') && !html.startsWith('\x00')) {
        html = '<p>' + html + '</p>';
    }

    // Restore PROTECTED blocks (Lists, Blockquotes) AFTER line break processing
    html = html.replace(/\x00PROTECTEDBLOCK(\d+)\x00/g, (match, index) => {
        return protectedBlocks[parseInt(index)];
    });

    // Clean up the final HTML
    // Remove <br/> tags immediately before block elements
    html = html.replace(/<br\/>\s*<pre>/g, '<pre>');
    html = html.replace(/<br\/>\s*<ul>/g, '<ul>');
    html = html.replace(/<br\/>\s*<ol>/g, '<ol>');
    html = html.replace(/<br\/>\s*<blockquote>/g, '<blockquote>');
    html = html.replace(/<br\/>\s*<h[1-6]>/g, '<h$1>');

    // Remove empty paragraphs
    html = html.replace(/<p>\s*<\/p>/g, '');
    html = html.replace(/<p>\s*<br\/>\s*<\/p>/g, '');

    // Remove excessive line breaks
    html = html.replace(/(<br\/>){3,}/g, '<br/><br/>'); // Max 2 consecutive line breaks
    html = html.replace(/(<\/p>)\s*(<p>)/g, '$1$2'); // Remove whitespace between paragraphs

    // Remove leading/trailing whitespace
    html = html.trim();

    // Add a style block to control spacing and margins in QML RichText
    const style = "<style>" +
        "h1 { margin-top: 0px; margin-bottom: 8px; }" +
        "h2 { margin-top: 12px; margin-bottom: 4px; }" +
        "h3 { margin-top: 8px; margin-bottom: 2px; }" +
        "p { margin-top: 0px; margin-bottom: 8px; }" +
        "ul, ol { margin-top: 0px; margin-bottom: 8px; }" +
        "li { margin-bottom: 0px; }" +
        "blockquote { margin-top: 4px; margin-bottom: 4px; }" +
        "</style>";

    return style + html;
}
