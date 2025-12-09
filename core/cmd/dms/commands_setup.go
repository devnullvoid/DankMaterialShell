package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/AvengeMedia/DankMaterialShell/core/internal/config"
	"github.com/AvengeMedia/DankMaterialShell/core/internal/deps"
	"github.com/AvengeMedia/DankMaterialShell/core/internal/log"
	"github.com/spf13/cobra"
)

var setupCmd = &cobra.Command{
	Use:   "setup",
	Short: "Deploy DMS configurations",
	Long:  "Deploy compositor and terminal configurations with interactive prompts",
	Run: func(cmd *cobra.Command, args []string) {
		if err := runSetup(); err != nil {
			log.Fatalf("Error during setup: %v", err)
		}
	},
}

func runSetup() error {
	fmt.Println("=== DMS Configuration Setup ===")

	wm, wmSelected := promptCompositor()
	terminal, terminalSelected := promptTerminal()
	useSystemd := promptSystemd()

	if !wmSelected && !terminalSelected {
		fmt.Println("No configurations selected. Exiting.")
		return nil
	}

	if wmSelected || terminalSelected {
		willBackup := checkExistingConfigs(wm, wmSelected, terminal, terminalSelected)
		if willBackup {
			fmt.Println("\n⚠ Existing configurations will be backed up with timestamps.")
		}

		fmt.Print("\nProceed with deployment? (y/N): ")
		var response string
		fmt.Scanln(&response)
		response = strings.ToLower(strings.TrimSpace(response))

		if response != "y" && response != "yes" {
			fmt.Println("Setup cancelled.")
			return nil
		}
	}

	fmt.Println("\nDeploying configurations...")
	logChan := make(chan string, 100)
	deployer := config.NewConfigDeployer(logChan)

	go func() {
		for msg := range logChan {
			fmt.Println("  " + msg)
		}
	}()

	ctx := context.Background()
	var results []config.DeploymentResult
	var err error

	if wmSelected && terminalSelected {
		results, err = deployer.DeployConfigurationsWithSystemd(ctx, wm, terminal, useSystemd)
	} else if wmSelected {
		results, err = deployer.DeployConfigurationsWithSystemd(ctx, wm, deps.TerminalGhostty, useSystemd)
		if len(results) > 1 {
			results = results[:1]
		}
	} else if terminalSelected {
		results, err = deployer.DeployConfigurationsWithSystemd(ctx, deps.WindowManagerNiri, terminal, useSystemd)
		if len(results) > 0 && results[0].ConfigType == "Niri" {
			results = results[1:]
		}
	}

	close(logChan)

	if err != nil {
		return fmt.Errorf("deployment failed: %w", err)
	}

	fmt.Println("\n=== Deployment Complete ===")
	for _, result := range results {
		if result.Deployed {
			fmt.Printf("✓ %s: %s\n", result.ConfigType, result.Path)
			if result.BackupPath != "" {
				fmt.Printf("  Backup: %s\n", result.BackupPath)
			}
		}
	}

	return nil
}

func promptCompositor() (deps.WindowManager, bool) {
	fmt.Println("Select compositor:")
	fmt.Println("1) Niri")
	fmt.Println("2) Hyprland")
	fmt.Println("3) None")

	var response string
	fmt.Print("\nChoice (1-3): ")
	fmt.Scanln(&response)
	response = strings.TrimSpace(response)

	switch response {
	case "1":
		return deps.WindowManagerNiri, true
	case "2":
		return deps.WindowManagerHyprland, true
	default:
		return deps.WindowManagerNiri, false
	}
}

func promptTerminal() (deps.Terminal, bool) {
	fmt.Println("\nSelect terminal:")
	fmt.Println("1) Ghostty")
	fmt.Println("2) Kitty")
	fmt.Println("3) Alacritty")
	fmt.Println("4) None")

	var response string
	fmt.Print("\nChoice (1-4): ")
	fmt.Scanln(&response)
	response = strings.TrimSpace(response)

	switch response {
	case "1":
		return deps.TerminalGhostty, true
	case "2":
		return deps.TerminalKitty, true
	case "3":
		return deps.TerminalAlacritty, true
	default:
		return deps.TerminalGhostty, false
	}
}

func promptSystemd() bool {
	fmt.Println("\nUse systemd for session management?")
	fmt.Println("1) Yes (recommended for most distros)")
	fmt.Println("2) No (standalone, no systemd integration)")

	var response string
	fmt.Print("\nChoice (1-2): ")
	fmt.Scanln(&response)
	response = strings.TrimSpace(response)

	return response != "2"
}

func checkExistingConfigs(wm deps.WindowManager, wmSelected bool, terminal deps.Terminal, terminalSelected bool) bool {
	homeDir := os.Getenv("HOME")
	willBackup := false

	if wmSelected {
		var configPath string
		switch wm {
		case deps.WindowManagerNiri:
			configPath = filepath.Join(homeDir, ".config", "niri", "config.kdl")
		case deps.WindowManagerHyprland:
			configPath = filepath.Join(homeDir, ".config", "hypr", "hyprland.conf")
		}

		if _, err := os.Stat(configPath); err == nil {
			willBackup = true
		}
	}

	if terminalSelected {
		var configPath string
		switch terminal {
		case deps.TerminalGhostty:
			configPath = filepath.Join(homeDir, ".config", "ghostty", "config")
		case deps.TerminalKitty:
			configPath = filepath.Join(homeDir, ".config", "kitty", "kitty.conf")
		case deps.TerminalAlacritty:
			configPath = filepath.Join(homeDir, ".config", "alacritty", "alacritty.toml")
		}

		if _, err := os.Stat(configPath); err == nil {
			willBackup = true
		}
	}

	return willBackup
}
