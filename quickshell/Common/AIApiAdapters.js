// QML JS library (not an ES module).
// Provider adapters for building curl commands.
// v1 supports OpenAI-compatible, Anthropic, and Gemini streaming.
// "custom" currently follows OpenAI-compatible semantics.

.pragma library

function buildCurlCommand(provider, payload, apiKey) {
    const request = buildRequest(provider, payload, apiKey);
    if (!request || !request.url)
        return null;

    const timeout = payload.timeout || 30;
    const baseCmd = [
        "curl",
        "-sS",
        "--no-buffer",
        "--show-error",
        "--connect-timeout",
        "5",
        "--max-time",
        String(timeout),
        "--compressed",
        "-w",
        "\\nDMS_STATUS:%{http_code}\\n"
    ];

    const cmd = baseCmd
        .concat(request.headers || [])
        .concat(["-d", request.body || "{}", request.url]);
    return cmd;
}

function buildRequest(provider, payload, apiKey) {
    switch (provider) {
    case "anthropic":
        return anthropicRequest(payload, apiKey);
    case "gemini":
        return geminiRequest(payload, apiKey);
    case "custom":
        return customRequest(payload, apiKey);
    default:
        return openaiRequest(payload, apiKey);
    }
}

function openaiRequest(payload, apiKey) {
    const url = (payload.baseUrl || "https://api.openai.com") + "/v1/chat/completions";
    const headers = ["-H", "Content-Type: application/json", "-H", "Authorization: Bearer " + apiKey];
    const body = {
        model: payload.model,
        messages: payload.messages,
        max_tokens: payload.max_tokens || 1024,
        temperature: payload.temperature || 0.7,
        stream: true
    };
    return { url, headers, body: JSON.stringify(body) };
}

function anthropicRequest(payload, apiKey) {
    const url = (payload.baseUrl || "https://api.anthropic.com") + "/v1/messages";
    const headers = [
        "-H", "Content-Type: application/json",
        "-H", "x-api-key: " + apiKey,
        "-H", "anthropic-version: 2023-06-01"
    ];
    const body = {
        model: payload.model,
        messages: payload.messages.map(m => ({ role: m.role === "assistant" ? "assistant" : "user", content: m.content })),
        max_tokens: payload.max_tokens || 1024,
        temperature: payload.temperature || 0.7,
        stream: true
    };
    return { url, headers, body: JSON.stringify(body) };
}

function geminiRequest(payload, apiKey) {
    const url = (payload.baseUrl || "https://generativelanguage.googleapis.com")
        + "/v1beta/models/" + (payload.model || "gemini-1.5-flash") + ":streamGenerateContent"
        + "?key=" + apiKey;
    const headers = ["-H", "Content-Type: application/json"];
    const contents = payload.messages.map(m => ({
        role: m.role === "user" ? "user" : "model",
        parts: [{ text: m.content }]
    }));
    const body = {
        contents,
        generationConfig: {
            temperature: payload.temperature || 0.7,
            maxOutputTokens: payload.max_tokens || 1024
        },
        stream: true
    };
    return { url, headers, body: JSON.stringify(body) };
}

function customRequest(payload, apiKey) {
    // v1 fallback: treat as OpenAI-compatible.
    return openaiRequest(payload, apiKey);
}
