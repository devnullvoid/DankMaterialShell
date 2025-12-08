package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"time"

	"github.com/AvengeMedia/DankMaterialShell/core/internal/log"
	"github.com/AvengeMedia/DankMaterialShell/core/internal/matugen"
	"github.com/AvengeMedia/DankMaterialShell/core/internal/server"
	"github.com/spf13/cobra"
)

var matugenCmd = &cobra.Command{
	Use:   "matugen",
	Short: "Generate Material Design themes",
	Long:  "Generate Material Design themes using matugen with dank16 color integration",
}

var matugenGenerateCmd = &cobra.Command{
	Use:   "generate",
	Short: "Generate theme synchronously",
	Run:   runMatugenGenerate,
}

var matugenQueueCmd = &cobra.Command{
	Use:   "queue",
	Short: "Queue theme generation (uses socket if available)",
	Run:   runMatugenQueue,
}

func init() {
	matugenCmd.AddCommand(matugenGenerateCmd)
	matugenCmd.AddCommand(matugenQueueCmd)

	for _, cmd := range []*cobra.Command{matugenGenerateCmd, matugenQueueCmd} {
		cmd.Flags().String("state-dir", "", "State directory for cache files")
		cmd.Flags().String("shell-dir", "", "DMS shell installation directory")
		cmd.Flags().String("config-dir", "", "User config directory")
		cmd.Flags().String("kind", "image", "Source type: image or hex")
		cmd.Flags().String("value", "", "Wallpaper path or hex color")
		cmd.Flags().String("mode", "dark", "Color mode: dark or light")
		cmd.Flags().String("icon-theme", "System Default", "Icon theme name")
		cmd.Flags().String("matugen-type", "scheme-tonal-spot", "Matugen scheme type")
		cmd.Flags().Bool("run-user-templates", true, "Run user matugen templates")
		cmd.Flags().String("stock-colors", "", "Stock theme colors JSON")
		cmd.Flags().Bool("sync-mode-with-portal", false, "Sync color scheme with GNOME portal")
		cmd.Flags().Bool("terminals-always-dark", false, "Force terminal themes to dark variant")
	}

	matugenQueueCmd.Flags().Bool("wait", true, "Wait for completion")
	matugenQueueCmd.Flags().Duration("timeout", 30*time.Second, "Timeout for waiting")
}

func buildMatugenOptions(cmd *cobra.Command) matugen.Options {
	stateDir, _ := cmd.Flags().GetString("state-dir")
	shellDir, _ := cmd.Flags().GetString("shell-dir")
	configDir, _ := cmd.Flags().GetString("config-dir")
	kind, _ := cmd.Flags().GetString("kind")
	value, _ := cmd.Flags().GetString("value")
	mode, _ := cmd.Flags().GetString("mode")
	iconTheme, _ := cmd.Flags().GetString("icon-theme")
	matugenType, _ := cmd.Flags().GetString("matugen-type")
	runUserTemplates, _ := cmd.Flags().GetBool("run-user-templates")
	stockColors, _ := cmd.Flags().GetString("stock-colors")
	syncModeWithPortal, _ := cmd.Flags().GetBool("sync-mode-with-portal")
	terminalsAlwaysDark, _ := cmd.Flags().GetBool("terminals-always-dark")

	return matugen.Options{
		StateDir:            stateDir,
		ShellDir:            shellDir,
		ConfigDir:           configDir,
		Kind:                kind,
		Value:               value,
		Mode:                mode,
		IconTheme:           iconTheme,
		MatugenType:         matugenType,
		RunUserTemplates:    runUserTemplates,
		StockColors:         stockColors,
		SyncModeWithPortal:  syncModeWithPortal,
		TerminalsAlwaysDark: terminalsAlwaysDark,
	}
}

func runMatugenGenerate(cmd *cobra.Command, args []string) {
	opts := buildMatugenOptions(cmd)
	if err := matugen.Run(opts); err != nil {
		log.Fatalf("Theme generation failed: %v", err)
	}
}

func runMatugenQueue(cmd *cobra.Command, args []string) {
	opts := buildMatugenOptions(cmd)
	wait, _ := cmd.Flags().GetBool("wait")
	timeout, _ := cmd.Flags().GetDuration("timeout")

	socketPath := os.Getenv("DMS_SOCKET")
	if socketPath == "" {
		var err error
		socketPath, err = server.FindSocket()
		if err != nil {
			log.Info("No socket available, running synchronously")
			if err := matugen.Run(opts); err != nil {
				log.Fatalf("Theme generation failed: %v", err)
			}
			return
		}
	}

	conn, err := net.Dial("unix", socketPath)
	if err != nil {
		log.Info("Socket connection failed, running synchronously")
		if err := matugen.Run(opts); err != nil {
			log.Fatalf("Theme generation failed: %v", err)
		}
		return
	}
	defer conn.Close()

	request := map[string]any{
		"id":     1,
		"method": "matugen.queue",
		"params": map[string]any{
			"stateDir":            opts.StateDir,
			"shellDir":            opts.ShellDir,
			"configDir":           opts.ConfigDir,
			"kind":                opts.Kind,
			"value":               opts.Value,
			"mode":                opts.Mode,
			"iconTheme":           opts.IconTheme,
			"matugenType":         opts.MatugenType,
			"runUserTemplates":    opts.RunUserTemplates,
			"stockColors":         opts.StockColors,
			"syncModeWithPortal":  opts.SyncModeWithPortal,
			"terminalsAlwaysDark": opts.TerminalsAlwaysDark,
			"wait":                wait,
		},
	}

	if err := json.NewEncoder(conn).Encode(request); err != nil {
		log.Fatalf("Failed to send request: %v", err)
	}

	if !wait {
		fmt.Println("Theme generation queued")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	resultCh := make(chan error, 1)
	go func() {
		var response struct {
			ID     int    `json:"id"`
			Result any    `json:"result"`
			Error  string `json:"error"`
		}
		if err := json.NewDecoder(conn).Decode(&response); err != nil {
			resultCh <- fmt.Errorf("failed to read response: %w", err)
			return
		}
		if response.Error != "" {
			resultCh <- fmt.Errorf("server error: %s", response.Error)
			return
		}
		resultCh <- nil
	}()

	select {
	case err := <-resultCh:
		if err != nil {
			log.Fatalf("Theme generation failed: %v", err)
		}
		fmt.Println("Theme generation completed")
	case <-ctx.Done():
		log.Fatalf("Timeout waiting for theme generation")
	}
}
