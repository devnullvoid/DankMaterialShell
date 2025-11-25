package main

import (
	"encoding/json"
	"fmt"
	"net"
	"os"

	"github.com/AvengeMedia/DankMaterialShell/core/internal/log"
	"github.com/AvengeMedia/DankMaterialShell/core/internal/server"
	"github.com/AvengeMedia/DankMaterialShell/core/internal/server/models"
	"github.com/spf13/cobra"
)

var openCmd = &cobra.Command{
	Use:   "open [url]",
	Short: "Open a URL in the browser picker",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		runOpen(args[0])
	},
}

func init() {
	rootCmd.AddCommand(openCmd)
}

func runOpen(url string) {
	socketPath, err := server.FindSocket()
	if err != nil {
		log.Warnf("DMS socket not found, falling back to xdg-open: %v", err)
		// Try xdg-open directly if we can't find the socket
		// But wait, if we are the default handler, calling xdg-open might loop?
		// We should probably just error out or try to find a browser manually.
		fmt.Println("DMS is not running. Please start DMS first.")
		os.Exit(1)
	}

	conn, err := net.Dial("unix", socketPath)
	if err != nil {
		// Fallback if DMS is not running
		log.Warnf("DMS socket not found, falling back to xdg-open: %v", err)
		fmt.Println("DMS is not running. Please start DMS first.")
		os.Exit(1)
	}
	defer conn.Close()

	// Read initial server info (capabilities)
	// We scan until newline
	buf := make([]byte, 1)
	for {
		_, err := conn.Read(buf)
		if err != nil {
			return
		}
		if buf[0] == '\n' {
			break
		}
	}

	req := models.Request{
		ID:     1,
		Method: "browser.open",
		Params: map[string]interface{}{
			"url": url,
		},
	}

	if err := json.NewEncoder(conn).Encode(req); err != nil {
		log.Fatalf("Failed to send request: %v", err)
	}

	// We don't strictly wait for response here as it's fire-and-forget for the CLI,
	// but we could wait for "ok" if we wanted to be sure.
}
