import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root

    property var messages: []
    property bool isStreaming: false
    property bool isOnline: false
    property string activeStreamId: ""

    // convenience aliases
    readonly property string provider: SettingsData.aiAssistantProvider || "openai"
    readonly property string baseUrl: SettingsData.aiAssistantBaseUrl || "https://api.openai.com"
    readonly property string model: SettingsData.aiAssistantModel || "gpt-4.1-mini"

    function resolveApiKey() {
        const p = provider;

        function scopedEnv(id) {
            switch (id) {
            case "anthropic":
                return Quickshell.env("DMS_ANTHROPIC_API_KEY") || "";
            case "gemini":
                return Quickshell.env("DMS_GEMINI_API_KEY") || "";
            case "custom":
                return Quickshell.env("DMS_CUSTOM_API_KEY") || "";
            default:
                return Quickshell.env("DMS_OPENAI_API_KEY") || "";
            }
        }

        function commonEnv(id) {
            switch (id) {
            case "anthropic":
                return Quickshell.env("ANTHROPIC_API_KEY") || "";
            case "gemini":
                return Quickshell.env("GEMINI_API_KEY") || "";
            case "custom":
                return "";
            default:
                return Quickshell.env("OPENAI_API_KEY") || "";
            }
        }

        const sessionKey = SettingsData.aiAssistantSessionApiKey || "";
        const savedKey = SettingsData.aiAssistantSaveApiKey ? (SettingsData.aiAssistantApiKey || "") : "";
        const common = commonEnv(p);
        const scoped = scopedEnv(p);

        return sessionKey || savedKey || common || scoped || "";
    }

    function sendMessage(text) {
        if (!text || text.trim().length === 0)
            return;

        if (isStreaming && chatFetcher.running) {
            markError(activeStreamId, I18n.tr("Please wait until the current response finishes."));
            return;
        }

        const now = Date.now();
        const streamId = "assistant-" + now;

        const userMsg = { role: "user", content: text, timestamp: now, id: "user-" + now, status: "ok" };
        const assistantMsg = { role: "assistant", content: "", timestamp: now + 1, id: streamId, status: "streaming" };

        messages = (messages || []).concat([userMsg, assistantMsg]);
        activeStreamId = streamId;
        isStreaming = true;

        const payload = buildPayload(text);
        const curlCmd = buildCurlCommand(payload);
        if (!curlCmd) {
            markError(streamId, I18n.tr("No API key or provider configuration."));
            return;
        }

        streamCollector.lastLen = 0;
        chatFetcher.command = curlCmd;
        chatFetcher.running = true;
    }

    function cancel() {
        if (!isStreaming)
            return;
        chatFetcher.running = false;
        markError(activeStreamId, I18n.tr("Cancelled"));
    }

    function markError(streamId, message) {
        isStreaming = false;
        messages = (messages || []).map(msg => {
            if (msg.id === streamId) {
                return { role: msg.role, content: message, timestamp: msg.timestamp, id: msg.id, status: "error" };
            }
            return msg;
        });
        activeStreamId = "";
    }

    function updateStreamContent(streamId, deltaText) {
        if (!deltaText)
            return;
        messages = (messages || []).map(msg => {
            if (msg.id === streamId) {
                return { role: msg.role, content: (msg.content || "") + deltaText, timestamp: msg.timestamp, id: msg.id, status: "streaming" };
            }
            return msg;
        });
    }

    function finalizeStream(streamId) {
        messages = (messages || []).map(msg => {
            if (msg.id === streamId) {
                return { role: msg.role, content: msg.content, timestamp: msg.timestamp, id: msg.id, status: "ok" };
            }
            return msg;
        });
        isStreaming = false;
        activeStreamId = "";
        isOnline = true;
    }

    function buildPayload(latestText) {
        // Build chat history excluding the streaming placeholder.
        const msgs = (messages || [])
            .filter(m => (m.role === "user" || m.role === "assistant") && m.status === "ok")
            .map(m => ({ role: m.role, content: m.content }));
        // Ensure the newest user message is present (in case of empty history).
        if (msgs.length === 0 || msgs[msgs.length - 1].role !== "user") {
            msgs.push({ role: "user", content: latestText });
        }
        return {
            provider: provider,
            baseUrl: baseUrl,
            model: model,
            temperature: SettingsData.aiAssistantTemperature,
            max_tokens: SettingsData.aiAssistantMaxTokens,
            messages: msgs,
            stream: true,
            timeout: SettingsData.aiAssistantTimeout
        };
    }

    function buildCurlCommand(payload) {
        const key = resolveApiKey();
        if (!key)
            return null;

        const url = provider === "openai" || provider === "custom" ? (payload.baseUrl || "https://api.openai.com") + "/v1/chat/completions"
                    : provider === "anthropic" ? (payload.baseUrl || "https://api.anthropic.com") + "/v1/messages"
                    : (payload.baseUrl || "https://generativelanguage.googleapis.com") + "/v1beta/models/" + (payload.model || "gemini-1.5-flash") + ":streamGenerateContent";

        const baseCmd = ["curl", "-sS", "--fail", "--no-buffer", "--connect-timeout", "5", "--max-time", String(payload.timeout || 30), "--compressed"];

        let headers = [];
        let body = {};

        if (provider === "anthropic") {
            headers = ["-H", "Content-Type: application/json", "-H", "x-api-key: " + key, "-H", "anthropic-version: 2023-06-01"];
            body = {
                model: payload.model,
                messages: payload.messages.map(m => ({ role: m.role === "assistant" ? "assistant" : "user", content: m.content })),
                max_tokens: payload.max_tokens || 1024,
                temperature: payload.temperature || 0.7,
                stream: true
            };
        } else if (provider === "gemini") {
            headers = ["-H", "Content-Type: application/json"];
            const contents = payload.messages.map(m => ({ role: m.role === "user" ? "user" : "model", parts: [{ text: m.content }] }));
            body = { contents: contents, generationConfig: { temperature: payload.temperature || 0.7, maxOutputTokens: payload.max_tokens || 1024 }, stream: true };
        } else { // openai/custom compatible
            headers = ["-H", "Content-Type: application/json", "-H", "Authorization: Bearer " + key];
            body = {
                model: payload.model,
                messages: payload.messages,
                max_tokens: payload.max_tokens || 1024,
                temperature: payload.temperature || 0.7,
                stream: true
            };
        }

        const bodyStr = JSON.stringify(body);
        const cmd = baseCmd.concat(headers).concat(["-d", bodyStr, url + (provider === "gemini" ? `?key=${key}` : "")]);
        return cmd;
    }

    property string streamBuffer: ""

    function handleStreamChunk(chunk) {
        // prepend any partial line saved from previous chunk
        let buffer = streamBuffer + chunk;
        const parts = buffer.split(/\r?\n/);

        // if the last char isn't a newline, keep the tail as partial
        if (buffer.length > 0 && !buffer.endsWith("\n") && !buffer.endsWith("\r")) {
            streamBuffer = parts.pop();
        } else {
            streamBuffer = "";
        }

        for (let i = 0; i < parts.length; i++) {
            const line = parts[i].trim();
            if (!line)
                continue;

            if (line === "data: [DONE]" || line === "data:[DONE]") {
                finalizeStream(activeStreamId);
                continue;
            }

            if (line.startsWith("data:")) {
                const jsonPart = line.substring(5).trim();
                parseProviderDelta(jsonPart);
            }
        }
    }

    function parseProviderDelta(jsonText) {
        try {
            const data = JSON.parse(jsonText);
            if (provider === "anthropic") {
                const delta = data.delta?.text || "";
                if (delta)
                    updateStreamContent(activeStreamId, delta);
                if (data.stop_reason)
                    finalizeStream(activeStreamId);
            } else if (provider === "gemini") {
                const parts = data.candidates?.[0]?.content?.parts || [];
                parts.forEach(p => {
                    if (p.text)
                        updateStreamContent(activeStreamId, p.text);
                });
            } else { // openai
                const deltas = data.choices?.[0]?.delta?.content;
                if (Array.isArray(deltas)) {
                    deltas.forEach(d => {
                        if (d.text)
                            updateStreamContent(activeStreamId, d.text);
                    });
                } else if (typeof deltas === "string") {
                    updateStreamContent(activeStreamId, deltas);
                }

                if (data.choices?.[0]?.finish_reason) {
                    finalizeStream(activeStreamId);
                }
            }
        } catch (e) {
            // ignore malformed chunks
        }
    }

    function handleStreamFinished(text) {
        if (isStreaming) {
            finalizeStream(activeStreamId);
        }
    }

    Process {
        id: chatFetcher
        running: false

        stdout: StdioCollector {
            id: streamCollector
            property int lastLen: 0

            onTextChanged: {
                const newData = text.substring(lastLen);
                lastLen = text.length;
                handleStreamChunk(newData);
            }

            onStreamFinished: {
                handleStreamFinished(text);
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0 && isStreaming) {
                markError(activeStreamId, I18n.tr("Request failed (exit %1)").arg(exitCode));
            }
        }
    }
}
