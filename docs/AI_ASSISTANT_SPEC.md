# AI Assistant Slideout — Feasibility & Specification

## 1) Summary
- Add a hotkey-toggleable AI chat panel that reuses the existing Notepad slideout shell pattern (`DankSlideout` + `Variants`).
- Talk to any OpenAI-compatible HTTP endpoint plus first-class adapters for Anthropic and Gemini; allow arbitrary local endpoints (Ollama/LM Studio/etc.).
- Ship minimal but production-ready v1: multi-turn chat with history per session, streaming responses, copy/export, and per-profile settings.

## 2) Goals
- **Fast invoke**: global hotkey to open/close; panel remembers last state per screen like Notepad.
- **Provider agnostic**: base URL + model string + API key for OpenAI-style; explicit adapters for Anthropic (messages) and Gemini (v1beta models); “custom HTTP” escape hatch for other POST schemas.
- **Privacy aware**: never send data without an explicit provider/key; warn when using remote endpoints; allow local-only mode.
- **Responsive UX**: streaming tokens, abort, retry, copy, and quick “insert to clipboard”.
- **Configurable**: per-user settings stored with the existing `SettingsData` / `settings.json` flow; optional per-screen visibility (mirrors Notepad `SettingsData.getFilteredScreens`).

## 3) Non‑Goals (v1)
- Tool-calling / function-calling is **out of scope for v1**, but layout/service hooks will be reserved to add it later without refactors.
- No multi-account switching inside one provider (one active profile at a time, but profiles can be pre-saved).
- No cloud sync of chat history; keep only local session cache (cleared on logout/restart unless user exports).

## 4) User stories
- Press a hotkey (e.g., `Mod+Shift+A`) to open the AI Assistant slideout on the focused screen, type a prompt, receive streaming reply, copy text.
- Toggle between “OpenAI-compatible”, “Anthropic”, and “Gemini” presets in Settings without reopening the panel; test connection with a built-in ping.
- Use a local HTTP endpoint (e.g., `http://localhost:11434/v1`) with custom headers and model name `llama3`.
- Pin the panel to stay open (expanded width) while coding; collapse when done.

## 5) UX / UI
- **Surface**: New `AIAssistant` module hosted inside `DankSlideout` with the same width/expand affordances as Notepad (`slideoutWidth: 480`, `expandedWidthValue: 960`, `customTransparency` honoring `SettingsData.aiAssistantTransparencyOverride`).
- **Layout**:
  - Header: title, provider badge, connection status dot, gear button → opens inline settings drawer.
  - Body: scrollable message list with compact bubbles; preserve Material 3 spacing/rounded corners used elsewhere.
  - Composer: multiline `TextArea`, `Ctrl+Enter` to send, `Esc` to close (like Notepad escape handling), buttons for Send / Stop / Copy last.
  - Optional “copy to clipboard” and “insert to focused window” actions (second one gated by IPC support—deferred if not available).
- **States**: idle, sending (spinner), streaming (token ticker), error (toast + retry button), offline (no provider configured).
- **Placement**: show per-display via `Variants` just like Notepad; should coexist with other popouts without stealing focus.
- **Accessibility**: respect global font scale; allow monospace toggle for code-heavy replies.

## 6) Architecture
- **Module**: `quickshell/Modules/AIAssistant/AIAssistant.qml` (UI shell) + `AIAssistantSettings.qml` (inline settings) + `MessageList.qml` / `MessageBubble.qml` (presentation).
- **Service**: `quickshell/Services/AIAssistantService.qml`
  - Handles chat state, message history, request/response pipeline, and persistence of the last session (in `~/.config/dms/ai-assistant-session.json`).
  - Uses `Process` + `curl` (matching WeatherService) for HTTP calls to keep dependencies minimal and allow streaming via `--no-buffer` and line-by-line stdout reads.
  - Supports **providers** via small adapters that build `curl` args:
    - **OpenAI-compatible**: POST `{baseUrl}/v1/chat/completions` with `model`, `messages`, `max_tokens`, `temperature`, `stream=true`.
    - **Anthropic**: POST `{baseUrl}/v1/messages` with `x-api-key`, `anthropic-version`, `model`, `messages`, `stream=true` SSE.
    - **Gemini**: POST `https://generativelanguage.googleapis.com/v1beta/models/{model}:streamGenerateContent` with `key` query param; fallback to non-stream endpoint if streaming fails.
    - **Custom**: user-provided method/path/body template + headers for niche providers.
  - Stream handling: parse `data:` lines; accumulate into UI-friendly chunks; allow cancel by killing the `Process`.
  - Error model: surface HTTP status + provider error text; retry button resends last payload.
- **Settings integration**:
  - `SettingsData` additions: `aiAssistantProvider` ("openai"|"anthropic"|"gemini"|"custom"), `aiAssistantBaseUrl`, `aiAssistantApiKey`, `aiAssistantModel`, `aiAssistantTemperature`, `aiAssistantMaxTokens`, `aiAssistantTimeout`, `aiAssistantTransparencyOverride`, `aiAssistantLastCustomTransparency`, `aiAssistantShowInScreens` (screen filter list), `aiAssistantUseMonospace`.
  - `Common/settings/SettingsSpec.js`: defaults plus validation ranges (temp 0–2, maxTokens 16–8192, timeout 5–120s).
  - `Modules/Settings/WidgetsTab`: new tile “AI Assistant” with link to detailed settings; `DisplaysTab` inclusion for per-screen toggles (mirrors Notepad id `"aiassistant"`).
  - `Modules/Settings/...` new tab or subsection under “Productivity” for provider config and a “Test Connection” button (fires a short `ping` request).
- **Popout plumbing**:
  - `DMSShell.qml`: add `Variants` block for `aiAssistantSlideoutVariants` mirroring Notepad, with `AIAssistant` content.
  - `PopoutService.qml`: track `aiAssistantSlideouts` with `show/hide/toggle` helpers.
  - `DMSShellIPC.qml`: new `IpcHandler { target: "aiassistant" ... }` with `open/close/toggle` like Notepad.
  - `Common/KeybindActions.js` and compositor configs (`core/internal/config/...`) get `Mod+Shift+A` default binding.
  - `Modules/DankBar` optional button (similar to `NotepadButton`) to toggle.
- **Persistence**: keep only the last session (messages) in a small JSON file; capped length (e.g., 50 messages) to avoid bloat; allow “Clear history” in UI.
- **Telemetry**: none; no network calls without user-provided endpoints/keys.
- **Tool-calling hooks (off by default)**: keep a dispatcher layer that can notice provider tool-call payloads and either drop them or render "pending tool" chips; UI keeps a hidden lane under assistant messages to show tool results when the feature is enabled in a later version.

## 7) Data model (UI)
- Message shape: `{ role: "user"|"assistant"|"system"|"tool", content: string, timestamp: number, id: string, status: "ok"|"streaming"|"error", toolCalls?: ToolCall[], toolResultFor?: string }` (tool fields unused in v1 but reserved).
- Session state: `{ messages: Message[], providerConfigHash: string, lastUsedModel: string }`.
- Provider config shape stored in settings for easy serialization; service computes a hash so changing provider wipes/resets session.

## 8) Security & privacy
- API key precedence (lowest → highest): built-in defaults (none) → provider-scoped env vars (`DMS_OPENAI_API_KEY`, `DMS_ANTHROPIC_API_KEY`, `DMS_GEMINI_API_KEY`, `DMS_CUSTOM_API_KEY`) → common env vars (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`) → settings-saved key (optional) → session-only key entered in UI. Surface the active source in settings and allow “clear saved key” to fall back to env.
- Never persist API keys in plain text logs; store in settings file only if user opts in, otherwise keep session-only in memory until restart.
- Redact keys in debug output and error toasts.
- Make remote-call disclaimer visible on first run and when provider changes from local → remote.
- Respect system proxy and SSL settings inherited by `curl`.

## 9) CLI considerations
- Slideout UX needs no CLI changes; IPC `aiassistant open|close|toggle` mirrors Notepad and works with existing `dms ipc call ...`.
- If later desired, a headless `dms ai` subcommand can call the same service over IPC; not required for POC.

## 10) Feasibility notes
- Reuses existing slideout/Variants/IPC patterns (identical to Notepad) → low risk for window management.
- Networking via `Process + curl` is already battle-tested in `WeatherService`; streaming is supported with `--no-buffer` and incremental stdout reads.
- Settings and translations follow established patterns; no new external deps.
- Known challenge: SSE parsing for Anthropic/Gemini; mitigated by handling `data:` lines and ignoring keep-alives; fallback to non-streaming if the transport misbehaves.

## 11) Deliverables
- New module files under `quickshell/Modules/AIAssistant/`.
- New service `quickshell/Services/AIAssistantService.qml`.
- Settings + IPC + keybind wiring (files listed in §6).
- Docs page (this spec) and a short user-facing blurb in `README` once implemented.

## 12) Rollout plan
1. Skeleton slideout + IPC/hotkey (no network) to validate focus/placement.
2. OpenAI-compatible adapter + non-streaming; ship behind “preview” toggle in settings.
3. Add streaming, cancel, and history persistence.
4. Add Anthropic + Gemini adapters and provider switcher UI.
5. Polish: monospace toggle, copy/export, translations, telemetry warning copy.

## 13) Open questions
- Do we want per-workspace memory (different chat sessions per compositor workspace)?
- When to enable tool/function calling by default once hooks are stable?
- Is there an existing secure store we can leverage for API keys instead of settings JSON?
- Should “insert into focused window” be allowed by default, or opt-in behind a warning?
