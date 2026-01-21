package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"strings"
	"sync"

	"github.com/alecthomas/chroma/v2"
	"github.com/alecthomas/chroma/v2/formatters/html"
	"github.com/alecthomas/chroma/v2/lexers"
	"github.com/alecthomas/chroma/v2/styles"
	"github.com/spf13/cobra"
	"github.com/yuin/goldmark"
	highlighting "github.com/yuin/goldmark-highlighting/v2"
	"github.com/yuin/goldmark/extension"
	"github.com/yuin/goldmark/parser"
	ghtml "github.com/yuin/goldmark/renderer/html"
)

var (
	chromaLanguage string
	chromaStyle    string
	chromaInline   bool
	chromaMarkdown bool

	// Caching layer for performance
	lexerCache     = make(map[string]chroma.Lexer)
	styleCache     = make(map[string]*chroma.Style)
	formatterCache = make(map[bool]*html.Formatter)
	cacheMutex     sync.RWMutex
	maxFileSize    = int64(5 * 1024 * 1024) // 5MB default
)

var chromaCmd = &cobra.Command{
	Use:   "chroma [file]",
	Short: "Syntax highlight source code",
	Long: `Generate syntax-highlighted HTML from source code.

Reads from file or stdin, outputs HTML with syntax highlighting.
Language is auto-detected from filename or can be specified with --language.

Examples:
  dms chroma main.go
  dms chroma --language python script.py
  echo "def foo(): pass" | dms chroma -l python
  cat code.rs | dms chroma -l rust --style dracula
  dms chroma --markdown README.md
  dms chroma --markdown --style github-dark notes.md
  dms chroma list-languages
  dms chroma list-styles`,
	Args: cobra.MaximumNArgs(1),
	Run:  runChroma,
}

var chromaListLanguagesCmd = &cobra.Command{
	Use:   "list-languages",
	Short: "List all supported languages",
	Run: func(cmd *cobra.Command, args []string) {
		for _, name := range lexers.Names(true) {
			fmt.Println(name)
		}
	},
}

var chromaListStylesCmd = &cobra.Command{
	Use:   "list-styles",
	Short: "List all available color styles",
	Run: func(cmd *cobra.Command, args []string) {
		for _, name := range styles.Names() {
			fmt.Println(name)
		}
	},
}

func init() {
	chromaCmd.Flags().StringVarP(&chromaLanguage, "language", "l", "", "Language for highlighting (auto-detect if not specified)")
	chromaCmd.Flags().StringVarP(&chromaStyle, "style", "s", "monokai", "Color style (monokai, dracula, github, etc.)")
	chromaCmd.Flags().BoolVar(&chromaInline, "inline", false, "Output inline styles instead of CSS classes")
	chromaCmd.Flags().BoolVarP(&chromaMarkdown, "markdown", "m", false, "Render markdown with syntax-highlighted code blocks")
	chromaCmd.Flags().Int64Var(&maxFileSize, "max-size", 5*1024*1024, "Maximum file size to process without warning (bytes)")

	chromaCmd.AddCommand(chromaListLanguagesCmd)
	chromaCmd.AddCommand(chromaListStylesCmd)
}

func getCachedLexer(key string, fallbackFunc func() chroma.Lexer) chroma.Lexer {
	cacheMutex.RLock()
	if lexer, ok := lexerCache[key]; ok {
		cacheMutex.RUnlock()
		return lexer
	}
	cacheMutex.RUnlock()

	lexer := fallbackFunc()
	if lexer != nil {
		cacheMutex.Lock()
		lexerCache[key] = lexer
		cacheMutex.Unlock()
	}
	return lexer
}

func getCachedStyle(name string) *chroma.Style {
	cacheMutex.RLock()
	if style, ok := styleCache[name]; ok {
		cacheMutex.RUnlock()
		return style
	}
	cacheMutex.RUnlock()

	style := styles.Get(name)
	if style == nil {
		fmt.Fprintf(os.Stderr, "Warning: Style '%s' not found, using fallback\n", name)
		style = styles.Fallback
	}

	cacheMutex.Lock()
	styleCache[name] = style
	cacheMutex.Unlock()
	return style
}

func getCachedFormatter(inline bool) *html.Formatter {
	cacheMutex.RLock()
	if formatter, ok := formatterCache[inline]; ok {
		cacheMutex.RUnlock()
		return formatter
	}
	cacheMutex.RUnlock()

	var formatter *html.Formatter
	if inline {
		formatter = html.New(html.WithClasses(false), html.TabWidth(4))
	} else {
		formatter = html.New(html.WithClasses(true), html.TabWidth(4))
	}

	cacheMutex.Lock()
	formatterCache[inline] = formatter
	cacheMutex.Unlock()
	return formatter
}

func runChroma(cmd *cobra.Command, args []string) {
	var source string
	var filename string

	// Read from file or stdin
	if len(args) > 0 {
		filename = args[0]

		// Check file size before reading
		fileInfo, err := os.Stat(filename)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error reading file info: %v\n", err)
			os.Exit(1)
		}

		if fileInfo.Size() > maxFileSize {
			fmt.Fprintf(os.Stderr, "Warning: File size (%d bytes) exceeds recommended limit (%d bytes)\n",
				fileInfo.Size(), maxFileSize)
			fmt.Fprintf(os.Stderr, "Processing may be slow. Consider using smaller files.\n")
		}

		content, err := os.ReadFile(filename)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error reading file: %v\n", err)
			os.Exit(1)
		}
		source = string(content)
	} else {
		content, err := io.ReadAll(os.Stdin)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error reading stdin: %v\n", err)
			os.Exit(1)
		}
		source = string(content)
	}

	// Handle empty input
	if strings.TrimSpace(source) == "" {
		return
	}

	// Handle Markdown rendering
	if chromaMarkdown {
		md := goldmark.New(
			goldmark.WithExtensions(
				extension.GFM,
				highlighting.NewHighlighting(
					highlighting.WithStyle(chromaStyle),
					highlighting.WithFormatOptions(
						html.WithClasses(!chromaInline),
					),
				),
			),
			goldmark.WithParserOptions(
				parser.WithAutoHeadingID(),
			),
			goldmark.WithRendererOptions(
				ghtml.WithHardWraps(),
				ghtml.WithXHTML(),
			),
		)

		var buf bytes.Buffer
		if err := md.Convert([]byte(source), &buf); err != nil {
			fmt.Fprintf(os.Stderr, "Markdown rendering error: %v\n", err)
			os.Exit(1)
		}
		fmt.Print(buf.String())
		return
	}

	// Detect or use specified lexer
	var lexer chroma.Lexer
	if chromaLanguage != "" {
		lexer = getCachedLexer(chromaLanguage, func() chroma.Lexer {
			l := lexers.Get(chromaLanguage)
			if l == nil {
				fmt.Fprintf(os.Stderr, "Unknown language: %s\n", chromaLanguage)
				os.Exit(1)
			}
			return l
		})
	} else if filename != "" {
		lexer = getCachedLexer("file:"+filename, func() chroma.Lexer {
			return lexers.Match(filename)
		})
	}

	// Try content analysis if no lexer found (limit to first 1KB for performance)
	if lexer == nil {
		analyzeContent := source
		if len(source) > 1024 {
			analyzeContent = source[:1024]
		}
		lexer = lexers.Analyse(analyzeContent)
		if lexer != nil {
			fmt.Fprintf(os.Stderr, "Info: Language auto-detected as '%s' from content analysis\n",
				lexer.Config().Name)
		}
	}

	// Fallback to plaintext
	if lexer == nil {
		fmt.Fprintf(os.Stderr, "Warning: Could not detect language, using plaintext\n")
		lexer = lexers.Fallback
	}

	lexer = chroma.Coalesce(lexer)

	// Get cached style
	style := getCachedStyle(chromaStyle)

	// Get cached formatter
	formatter := getCachedFormatter(chromaInline)

	// Tokenize
	iterator, err := lexer.Tokenise(nil, source)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Tokenization error: %v\n", err)
		os.Exit(1)
	}

	// Format and output
	if err := formatter.Format(os.Stdout, style, iterator); err != nil {
		fmt.Fprintf(os.Stderr, "Formatting error: %v\n", err)
		os.Exit(1)
	}
}
