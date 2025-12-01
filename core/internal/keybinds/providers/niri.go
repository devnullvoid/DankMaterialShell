package providers

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/AvengeMedia/DankMaterialShell/core/internal/keybinds"
)

type NiriProvider struct {
	configDir string
}

func NewNiriProvider(configDir string) *NiriProvider {
	if configDir == "" {
		configDir = defaultNiriConfigDir()
	}
	return &NiriProvider{
		configDir: configDir,
	}
}

func defaultNiriConfigDir() string {
	configHome := os.Getenv("XDG_CONFIG_HOME")
	if configHome != "" {
		return filepath.Join(configHome, "niri")
	}

	home, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	return filepath.Join(home, ".config", "niri")
}

func (n *NiriProvider) Name() string {
	return "niri"
}

func (n *NiriProvider) GetCheatSheet() (*keybinds.CheatSheet, error) {
	section, err := ParseNiriKeys(n.configDir)
	if err != nil {
		return nil, fmt.Errorf("failed to parse niri config: %w", err)
	}

	categorizedBinds := make(map[string][]keybinds.Keybind)
	n.convertSection(section, "", categorizedBinds)

	return &keybinds.CheatSheet{
		Title:    "Niri Keybinds",
		Provider: n.Name(),
		Binds:    categorizedBinds,
	}, nil
}

func (n *NiriProvider) convertSection(section *NiriSection, subcategory string, categorizedBinds map[string][]keybinds.Keybind) {
	currentSubcat := subcategory
	if section.Name != "" {
		currentSubcat = section.Name
	}

	for _, kb := range section.Keybinds {
		category := n.categorizeByAction(kb.Action)
		bind := n.convertKeybind(&kb, currentSubcat)
		categorizedBinds[category] = append(categorizedBinds[category], bind)
	}

	for _, child := range section.Children {
		n.convertSection(&child, currentSubcat, categorizedBinds)
	}
}

func (n *NiriProvider) categorizeByAction(action string) string {
	switch {
	case action == "next-window" || action == "previous-window":
		return "Alt-Tab"
	case strings.Contains(action, "screenshot"):
		return "Screenshot"
	case action == "show-hotkey-overlay" || action == "toggle-overview":
		return "Overview"
	case action == "quit" ||
		action == "power-off-monitors" ||
		action == "toggle-keyboard-shortcuts-inhibit" ||
		strings.Contains(action, "dpms"):
		return "System"
	case action == "spawn":
		return "Execute"
	case strings.Contains(action, "workspace"):
		return "Workspace"
	case strings.HasPrefix(action, "focus-monitor") ||
		strings.HasPrefix(action, "move-column-to-monitor") ||
		strings.HasPrefix(action, "move-window-to-monitor"):
		return "Monitor"
	case strings.Contains(action, "window") ||
		strings.Contains(action, "focus") ||
		strings.Contains(action, "move") ||
		strings.Contains(action, "swap") ||
		strings.Contains(action, "resize") ||
		strings.Contains(action, "column"):
		return "Window"
	default:
		return "Other"
	}
}

func (n *NiriProvider) convertKeybind(kb *NiriKeyBinding, subcategory string) keybinds.Keybind {
	key := n.formatKey(kb)
	desc := kb.Description
	rawAction := n.formatRawAction(kb.Action, kb.Args)

	if desc == "" {
		desc = rawAction
	}

	return keybinds.Keybind{
		Key:         key,
		Description: desc,
		Action:      rawAction,
		Subcategory: subcategory,
	}
}

func (n *NiriProvider) formatRawAction(action string, args []string) string {
	if len(args) == 0 {
		return action
	}
	return action + " " + strings.Join(args, " ")
}

func (n *NiriProvider) formatKey(kb *NiriKeyBinding) string {
	parts := make([]string, 0, len(kb.Mods)+1)
	parts = append(parts, kb.Mods...)
	parts = append(parts, kb.Key)
	return strings.Join(parts, "+")
}
