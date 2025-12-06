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
)

func DetectCompositor() Compositor {
	if os.Getenv("HYPRLAND_INSTANCE_SIGNATURE") != "" {
		return CompositorHyprland
	}
	return CompositorUnknown
}

type WindowGeometry struct {
	X      int32
	Y      int32
	Width  int32
	Height int32
}

func GetActiveWindow() (*WindowGeometry, error) {
	compositor := DetectCompositor()

	switch compositor {
	case CompositorHyprland:
		return getHyprlandActiveWindow()
	default:
		return nil, fmt.Errorf("window capture requires Hyprland (other compositors not yet supported)")
	}
}

type hyprlandWindow struct {
	At   [2]int32 `json:"at"`
	Size [2]int32 `json:"size"`
}

func getHyprlandActiveWindow() (*WindowGeometry, error) {
	cmd := exec.Command("hyprctl", "-j", "activewindow")
	output, err := cmd.Output()
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
