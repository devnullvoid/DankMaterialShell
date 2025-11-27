package main

import (
	"encoding/json"
	"fmt"
	"net"
	"os"
	"strings"

	"github.com/AvengeMedia/DankMaterialShell/core/internal/log"
	"github.com/AvengeMedia/DankMaterialShell/core/internal/server"
	"github.com/AvengeMedia/DankMaterialShell/core/internal/server/models"
	"github.com/spf13/cobra"
)

var (
	openMimeType     string
	openCategories   []string
	openRequestType  string
)

var openCmd = &cobra.Command{
	Use:   "open [target]",
	Short: "Open a file, URL, or resource with an application picker",
	Long: `Open a target (URL, file, or other resource) using the DMS application picker.
By default, this opens URLs with the browser picker. You can customize the behavior
with flags to handle different MIME types or application categories.

Examples:
  dms open https://example.com                    # Open URL with browser picker
  dms open file.pdf --mime application/pdf        # Open PDF with compatible apps
  dms open document.odt --category Office         # Open with office applications
  dms open --mime image/png image.png             # Open image with image viewers`,
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		runOpen(args[0])
	},
}

func init() {
	rootCmd.AddCommand(openCmd)
	openCmd.Flags().StringVarP(&openMimeType, "mime", "m", "", "MIME type for filtering applications")
	openCmd.Flags().StringSliceVarP(&openCategories, "category", "c", []string{}, "Application categories to filter (e.g., WebBrowser, Office, Graphics)")
	openCmd.Flags().StringVarP(&openRequestType, "type", "t", "url", "Request type (url, file, or custom)")
}

func runOpen(target string) {
	socketPath, err := server.FindSocket()
	if err != nil {
		log.Warnf("DMS socket not found: %v", err)
		fmt.Println("DMS is not running. Please start DMS first.")
		os.Exit(1)
	}

	conn, err := net.Dial("unix", socketPath)
	if err != nil {
		log.Warnf("DMS socket connection failed: %v", err)
		fmt.Println("DMS is not running. Please start DMS first.")
		os.Exit(1)
	}
	defer conn.Close()

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

	params := map[string]interface{}{
		"target": target,
	}

	if openMimeType != "" {
		params["mimeType"] = openMimeType
	}

	if len(openCategories) > 0 {
		params["categories"] = openCategories
	}

	if openRequestType != "" {
		params["requestType"] = openRequestType
	}

	method := "apppicker.open"
	if openMimeType == "" && len(openCategories) == 0 && (strings.HasPrefix(target, "http://") || strings.HasPrefix(target, "https://")) {
		method = "browser.open"
		params["url"] = target
	}

	req := models.Request{
		ID:     1,
		Method: method,
		Params: params,
	}

	if err := json.NewEncoder(conn).Encode(req); err != nil {
		log.Fatalf("Failed to send request: %v", err)
	}
}
