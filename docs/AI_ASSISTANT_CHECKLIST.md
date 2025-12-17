# AI Assistant Development Checklist

Use this alongside `docs/AI_ASSISTANT_SPEC.md` when implementing v1.

## Scaffolding
- [x] Create module folder: `quickshell/Modules/AIAssistant/` with placeholders: `AIAssistant.qml`, `AIAssistantSettings.qml`, `MessageList.qml`, `MessageBubble.qml`.
- [x] Add service: `quickshell/Services/AIAssistantService.qml` (stub state + request pipeline).
- [x] Add adapter helper: `quickshell/Common/AIApiAdapters.js` (build curl args per provider + tool-call stubs reserved).

## Shell wiring
- [x] `DMSShell.qml`: add `aiAssistantSlideoutVariants` (copied from Notepad structure) and include in `DMSShellIPC` props.
- [ ] `PopoutService.qml`: track `aiAssistantSlideouts` with `show/hide/toggle` helpers.
- [x] `DMSShellIPC.qml`: new `IpcHandler { target: "aiassistant"; open/close/toggle }`.
- [x] `Common/KeybindActions.js` + compositor configs (`core/internal/config/...`): add default `Mod+Shift+A` binding.
- [x] Optional: `Modules/DankBar` button component to toggle the assistant.

## Settings integration
- [x] `Common/SettingsData.qml` + `Common/settings/SettingsSpec.js`: add AI settings (provider, baseUrl, model, temp, maxTokens, timeout, transparency, monospace, screen filter, api key save/session-only flags).
- [x] Settings UI: new section with SettingsCard components, provider selector, model/URL fields (DankTextField), temperature/max tokens/timeout sliders, monospace toggle, session-only key toggle, key source indicator. Uses proper DMS styling with SettingsDropdownRow, SettingsToggleRow, SettingsSliderRow.
- [x] `DisplaysTab.qml`: include `"aiassistant"` id for per-screen visibility (mirrors Notepad flow).

## Networking core (service)
- [x] Implement env precedence: DMS_* keys → common envs → saved key → session-only key.
- [x] Build curl command with `--no-buffer`, timeouts, headers; support OpenAI-compatible, Anthropic, Gemini, Custom.
- [x] Streaming handling: parse `data:` lines; accumulate chunks; cancel by stopping Process.
- [x] Error handling: surface HTTP status + body; retry hook.
- [x] Persistence: save last session JSON (cap ~50 messages) to config dir; reset on provider hash change.

## UI behavior
- [x] Layout per spec: header (title, provider badge, status dot, gear), body message list, composer with Send/Stop/Copy, hotkeys `Ctrl+Enter` send, `Esc` close. Composer uses proper ScrollView with sized container to prevent overflow. Send/Stop buttons use DankButton with icons and theming.
- [ ] States: idle/sending/streaming/error/offline; toast + inline retry on error.
- [x] Monospace toggle respected; transparency via Theme values; follow font scale.
- [x] Copy last reply action; optional clipboard/insert-to-window hook (stub if IPC not ready).

## IPC & commands
- [ ] Verify `dms ipc call aiassistant toggle` works.
- [ ] Add first-run disclaimer for remote calls.

## Translations & theme
- [ ] Add strings to translations template after copy stabilizes.
- [x] Confirm colors/spacing match existing Material-3 style. UI now uses SettingsCard, DankButton, DankTextField, DankSlider, and other standard DMS components with consistent theming.

## Testing
- [ ] Manual smoke with local mock endpoint and streaming path.
- [ ] Validate hotkey on Hyprland + Niri sample configs.
- [ ] Optional lightweight QML test for open/close + send cancel.

## Backlog (post-v1)
- [ ] Enable tool-calling path using reserved fields/dispatcher.
- [ ] Headless `dms ai` CLI subcommand.
- [ ] "Insert into focused window" action with opt-in warning.
- [ ] Secure key storage option (if available platform-side).
