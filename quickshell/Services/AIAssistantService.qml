import QtQuick
import Quickshell
import qs.Common

QtObject {
    id: root

    property var messages: []
    property bool isStreaming: false
    property bool isOnline: false

    function resolveApiKey() {
        const provider = SettingsData.aiAssistantProvider || "openai";

        function scopedEnv(p) {
            switch (p) {
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

        function commonEnv(p) {
            switch (p) {
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
        const common = commonEnv(provider);
        const scoped = scopedEnv(provider);

        return sessionKey || savedKey || common || scoped || "";
    }

    function sendMessage(text) {
        const now = Date.now();
        const userMsg = {
            role: "user",
            content: text,
            timestamp: now,
            id: "user-" + now,
            status: "ok"
        };

        messages = (messages || []).concat([userMsg, {
            role: "assistant",
            content: I18n.tr("Thinking… (network stub)"),
            timestamp: now + 1,
            id: "assistant-" + now,
            status: "streaming"
        }]);

        isStreaming = true;

        // Stubbed response until networking is implemented
        Qt.callLater(() => {
            const updated = messages.map(msg => {
                if (msg.id === "assistant-" + now) {
                    return {
                        role: "assistant",
                        content: I18n.tr("This is a placeholder response while networking is being wired."),
                        timestamp: msg.timestamp,
                        id: msg.id,
                        status: "ok"
                    };
                }
                return msg;
            });
            messages = updated;
            isStreaming = false;
            isOnline = true;
        });
    }

    function cancel() {
        if (!isStreaming)
            return;
        isStreaming = false;
        messages = messages.map(msg => {
            if (msg.status === "streaming") {
                return {
                    role: msg.role,
                    content: I18n.tr("Cancelled"),
                    timestamp: msg.timestamp,
                    id: msg.id,
                    status: "error"
                };
            }
            return msg;
        });
    }
}
