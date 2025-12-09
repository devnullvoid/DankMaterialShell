package utils

import (
	"os"
	"path/filepath"
	"testing"
)

func TestExpandPathTilde(t *testing.T) {
	home, err := os.UserHomeDir()
	if err != nil {
		t.Skip("no home directory")
	}
	result, err := ExpandPath("~/test")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	expected := filepath.Join(home, "test")
	if result != expected {
		t.Errorf("expected %s, got %s", expected, result)
	}
}

func TestExpandPathEnvVar(t *testing.T) {
	t.Setenv("TEST_PATH_VAR", "/custom/path")
	result, err := ExpandPath("$TEST_PATH_VAR/subdir")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if result != "/custom/path/subdir" {
		t.Errorf("expected /custom/path/subdir, got %s", result)
	}
}

func TestExpandPathAbsolute(t *testing.T) {
	result, err := ExpandPath("/absolute/path")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if result != "/absolute/path" {
		t.Errorf("expected /absolute/path, got %s", result)
	}
}

func TestXDGConfigHomeDefault(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", "")
	home, err := os.UserHomeDir()
	if err != nil {
		t.Skip("no home directory")
	}
	result := XDGConfigHome()
	expected := filepath.Join(home, ".config")
	if result != expected {
		t.Errorf("expected %s, got %s", expected, result)
	}
}

func TestXDGConfigHomeCustom(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", "/custom/config")
	result := XDGConfigHome()
	if result != "/custom/config" {
		t.Errorf("expected /custom/config, got %s", result)
	}
}

func TestXDGCacheHomeDefault(t *testing.T) {
	t.Setenv("XDG_CACHE_HOME", "")
	home, err := os.UserHomeDir()
	if err != nil {
		t.Skip("no home directory")
	}
	result := XDGCacheHome()
	expected := filepath.Join(home, ".cache")
	if result != expected {
		t.Errorf("expected %s, got %s", expected, result)
	}
}

func TestXDGCacheHomeCustom(t *testing.T) {
	t.Setenv("XDG_CACHE_HOME", "/custom/cache")
	result := XDGCacheHome()
	if result != "/custom/cache" {
		t.Errorf("expected /custom/cache, got %s", result)
	}
}

func TestXDGDataHomeDefault(t *testing.T) {
	t.Setenv("XDG_DATA_HOME", "")
	home, err := os.UserHomeDir()
	if err != nil {
		t.Skip("no home directory")
	}
	result := XDGDataHome()
	expected := filepath.Join(home, ".local", "share")
	if result != expected {
		t.Errorf("expected %s, got %s", expected, result)
	}
}

func TestXDGDataHomeCustom(t *testing.T) {
	t.Setenv("XDG_DATA_HOME", "/custom/data")
	result := XDGDataHome()
	if result != "/custom/data" {
		t.Errorf("expected /custom/data, got %s", result)
	}
}
