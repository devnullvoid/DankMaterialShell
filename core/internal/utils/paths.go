package utils

import (
	"os"
	"path/filepath"
	"strings"
)

func ExpandPath(path string) (string, error) {
	expanded := os.ExpandEnv(path)
	expanded = filepath.Clean(expanded)

	if strings.HasPrefix(expanded, "~") {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", err
		}
		expanded = filepath.Join(home, expanded[1:])
	}

	return expanded, nil
}
