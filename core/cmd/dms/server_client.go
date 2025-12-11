package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"path/filepath"

	"github.com/AvengeMedia/DankMaterialShell/core/internal/server"
)

type serverResponse struct {
	ID     int    `json:"id,omitempty"`
	Result any    `json:"result,omitempty"`
	Error  string `json:"error,omitempty"`
}

func sendServerRequest(req map[string]any) (*serverResponse, error) {
	socketPath := getServerSocketPath()

	conn, err := net.Dial("unix", socketPath)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to server (is it running?): %w", err)
	}
	defer conn.Close()

	scanner := bufio.NewScanner(conn)
	scanner.Scan() // discard initial capabilities message

	reqData, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	if _, err := conn.Write(reqData); err != nil {
		return nil, fmt.Errorf("failed to write request: %w", err)
	}

	if _, err := conn.Write([]byte("\n")); err != nil {
		return nil, fmt.Errorf("failed to write newline: %w", err)
	}

	if !scanner.Scan() {
		return nil, fmt.Errorf("failed to read response")
	}

	var resp serverResponse
	if err := json.Unmarshal(scanner.Bytes(), &resp); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %w", err)
	}

	return &resp, nil
}

func getServerSocketPath() string {
	runtimeDir := os.Getenv("XDG_RUNTIME_DIR")
	if runtimeDir == "" {
		runtimeDir = os.TempDir()
	}

	entries, err := os.ReadDir(runtimeDir)
	if err != nil {
		return filepath.Join(runtimeDir, "danklinux.sock")
	}

	for _, entry := range entries {
		name := entry.Name()
		if name == "danklinux.sock" {
			return filepath.Join(runtimeDir, name)
		}
		if len(name) > 10 && name[:10] == "danklinux-" && filepath.Ext(name) == ".sock" {
			return filepath.Join(runtimeDir, name)
		}
	}

	return server.GetSocketPath()
}
