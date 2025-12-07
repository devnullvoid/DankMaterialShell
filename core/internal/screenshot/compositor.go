package screenshot

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
)

type Compositor int

const (
	CompositorUnknown Compositor = iota
	CompositorHyprland
	CompositorSway
	CompositorNiri
	CompositorDWL
)

var detectedCompositor Compositor = -1

func DetectCompositor() Compositor {
	if detectedCompositor >= 0 {
		return detectedCompositor
	}

	hyprlandSig := os.Getenv("HYPRLAND_INSTANCE_SIGNATURE")
	niriSocket := os.Getenv("NIRI_SOCKET")
	swaySocket := os.Getenv("SWAYSOCK")

	switch {
	case niriSocket != "":
		if _, err := os.Stat(niriSocket); err == nil {
			detectedCompositor = CompositorNiri
			return detectedCompositor
		}
	case swaySocket != "":
		if _, err := os.Stat(swaySocket); err == nil {
			detectedCompositor = CompositorSway
			return detectedCompositor
		}
	case hyprlandSig != "":
		detectedCompositor = CompositorHyprland
		return detectedCompositor
	}

	detectedCompositor = CompositorUnknown
	return detectedCompositor
}

func SetCompositorDWL() {
	detectedCompositor = CompositorDWL
}

type WindowGeometry struct {
	X      int32
	Y      int32
	Width  int32
	Height int32
}

func GetActiveWindow() (*WindowGeometry, error) {
	switch DetectCompositor() {
	case CompositorHyprland:
		return getHyprlandActiveWindow()
	default:
		return nil, fmt.Errorf("window capture requires Hyprland")
	}
}

type hyprlandWindow struct {
	At   [2]int32 `json:"at"`
	Size [2]int32 `json:"size"`
}

func getHyprlandActiveWindow() (*WindowGeometry, error) {
	output, err := exec.Command("hyprctl", "-j", "activewindow").Output()
	if err != nil {
		return nil, fmt.Errorf("hyprctl activewindow: %w", err)
	}

	var win hyprlandWindow
	if err := json.Unmarshal(output, &win); err != nil {
		return nil, fmt.Errorf("parse activewindow: %w", err)
	}

	if win.Size[0] <= 0 || win.Size[1] <= 0 {
		return nil, fmt.Errorf("no active window")
	}

	return &WindowGeometry{
		X:      win.At[0],
		Y:      win.At[1],
		Width:  win.Size[0],
		Height: win.Size[1],
	}, nil
}

type hyprlandMonitor struct {
	Name    string  `json:"name"`
	X       int32   `json:"x"`
	Y       int32   `json:"y"`
	Width   int32   `json:"width"`
	Height  int32   `json:"height"`
	Scale   float64 `json:"scale"`
	Focused bool    `json:"focused"`
}

func GetHyprlandMonitorScale(name string) float64 {
	output, err := exec.Command("hyprctl", "-j", "monitors").Output()
	if err != nil {
		return 0
	}

	var monitors []hyprlandMonitor
	if err := json.Unmarshal(output, &monitors); err != nil {
		return 0
	}

	for _, m := range monitors {
		if m.Name == name {
			return m.Scale
		}
	}
	return 0
}

func getHyprlandFocusedMonitor() string {
	output, err := exec.Command("hyprctl", "-j", "monitors").Output()
	if err != nil {
		return ""
	}

	var monitors []hyprlandMonitor
	if err := json.Unmarshal(output, &monitors); err != nil {
		return ""
	}

	for _, m := range monitors {
		if m.Focused {
			return m.Name
		}
	}
	return ""
}

func GetHyprlandMonitorGeometry(name string) (x, y, w, h int32, ok bool) {
	output, err := exec.Command("hyprctl", "-j", "monitors").Output()
	if err != nil {
		return 0, 0, 0, 0, false
	}

	var monitors []hyprlandMonitor
	if err := json.Unmarshal(output, &monitors); err != nil {
		return 0, 0, 0, 0, false
	}

	for _, m := range monitors {
		if m.Name == name {
			logicalW := int32(float64(m.Width) / m.Scale)
			logicalH := int32(float64(m.Height) / m.Scale)
			return m.X, m.Y, logicalW, logicalH, true
		}
	}
	return 0, 0, 0, 0, false
}

type swayWorkspace struct {
	Output  string `json:"output"`
	Focused bool   `json:"focused"`
}

func getSwayFocusedMonitor() string {
	output, err := exec.Command("swaymsg", "-t", "get_workspaces").Output()
	if err != nil {
		return ""
	}

	var workspaces []swayWorkspace
	if err := json.Unmarshal(output, &workspaces); err != nil {
		return ""
	}

	for _, ws := range workspaces {
		if ws.Focused {
			return ws.Output
		}
	}
	return ""
}

type niriWorkspace struct {
	Output    string `json:"output"`
	IsFocused bool   `json:"is_focused"`
}

func getNiriFocusedMonitor() string {
	output, err := exec.Command("niri", "msg", "-j", "workspaces").Output()
	if err != nil {
		return ""
	}

	var workspaces []niriWorkspace
	if err := json.Unmarshal(output, &workspaces); err != nil {
		return ""
	}

	for _, ws := range workspaces {
		if ws.IsFocused {
			return ws.Output
		}
	}
	return ""
}

var dwlActiveOutput string

func SetDWLActiveOutput(name string) {
	dwlActiveOutput = name
}

func getDWLFocusedMonitor() string {
	return dwlActiveOutput
}

func GetFocusedMonitor() string {
	switch DetectCompositor() {
	case CompositorHyprland:
		return getHyprlandFocusedMonitor()
	case CompositorSway:
		return getSwayFocusedMonitor()
	case CompositorNiri:
		return getNiriFocusedMonitor()
	case CompositorDWL:
		return getDWLFocusedMonitor()
	}
	return ""
}
