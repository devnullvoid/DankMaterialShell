// Placeholder adapter helpers. Extend to build curl argument lists per provider.

function buildRequest(provider, payload) {
    switch (provider) {
    case "anthropic":
        return anthropicRequest(payload);
    case "gemini":
        return geminiRequest(payload);
    case "custom":
        return customRequest(payload);
    default:
        return openaiRequest(payload);
    }
}

function openaiRequest(payload) {
    return {
        url: (payload.baseUrl || "https://api.openai.com") + "/v1/chat/completions",
        headers: payload.headers || [],
        body: JSON.stringify(payload.body || {})
    };
}

function anthropicRequest(payload) {
    return {
        url: (payload.baseUrl || "https://api.anthropic.com") + "/v1/messages",
        headers: payload.headers || [],
        body: JSON.stringify(payload.body || {})
    };
}

function geminiRequest(payload) {
    return {
        url: (payload.baseUrl || "https://generativelanguage.googleapis.com") + "/v1beta/models/" + (payload.model || "gemini-1.5-flash") + ":streamGenerateContent",
        headers: payload.headers || [],
        body: JSON.stringify(payload.body || {})
    };
}

function customRequest(payload) {
    return {
        url: (payload.baseUrl || "") + (payload.path || ""),
        headers: payload.headers || [],
        body: JSON.stringify(payload.body || {})
    };
}

export { buildRequest };
