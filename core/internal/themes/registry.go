package themes

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/go-git/go-git/v6"
	"github.com/spf13/afero"
)

const registryRepo = "https://github.com/AvengeMedia/dms-plugin-registry.git"

type ColorScheme struct {
	Primary              string `json:"primary"`
	PrimaryText          string `json:"primaryText"`
	PrimaryContainer     string `json:"primaryContainer"`
	Secondary            string `json:"secondary"`
	Surface              string `json:"surface"`
	SurfaceText          string `json:"surfaceText"`
	SurfaceVariant       string `json:"surfaceVariant"`
	SurfaceVariantText   string `json:"surfaceVariantText"`
	SurfaceTint          string `json:"surfaceTint"`
	Background           string `json:"background"`
	BackgroundText       string `json:"backgroundText"`
	Outline              string `json:"outline"`
	SurfaceContainer     string `json:"surfaceContainer"`
	SurfaceContainerHigh string `json:"surfaceContainerHigh"`
	Error                string `json:"error"`
	Warning              string `json:"warning"`
	Info                 string `json:"info"`
}

type Theme struct {
	ID          string      `json:"id"`
	Name        string      `json:"name"`
	Version     string      `json:"version"`
	Author      string      `json:"author"`
	Description string      `json:"description"`
	Dark        ColorScheme `json:"dark"`
	Light       ColorScheme `json:"light"`
	PreviewPath string      `json:"-"`
	SourceDir   string      `json:"sourceDir,omitempty"`
}

type GitClient interface {
	PlainClone(path string, url string) error
	Pull(path string) error
}

type realGitClient struct{}

func (g *realGitClient) PlainClone(path string, url string) error {
	_, err := git.PlainClone(path, &git.CloneOptions{
		URL:      url,
		Progress: os.Stdout,
	})
	return err
}

func (g *realGitClient) Pull(path string) error {
	repo, err := git.PlainOpen(path)
	if err != nil {
		return err
	}

	worktree, err := repo.Worktree()
	if err != nil {
		return err
	}

	err = worktree.Pull(&git.PullOptions{})
	if err != nil && err.Error() != "already up-to-date" {
		return err
	}

	return nil
}

type Registry struct {
	fs       afero.Fs
	cacheDir string
	themes   []Theme
	git      GitClient
}

func NewRegistry() (*Registry, error) {
	return NewRegistryWithFs(afero.NewOsFs())
}

func NewRegistryWithFs(fs afero.Fs) (*Registry, error) {
	cacheDir := getCacheDir()
	return &Registry{
		fs:       fs,
		cacheDir: cacheDir,
		git:      &realGitClient{},
	}, nil
}

func getCacheDir() string {
	return filepath.Join(os.TempDir(), "dankdots-plugin-registry")
}

func (r *Registry) Update() error {
	exists, err := afero.DirExists(r.fs, r.cacheDir)
	if err != nil {
		return fmt.Errorf("failed to check cache directory: %w", err)
	}

	if !exists {
		if err := r.fs.MkdirAll(filepath.Dir(r.cacheDir), 0755); err != nil {
			return fmt.Errorf("failed to create cache directory: %w", err)
		}

		if err := r.git.PlainClone(r.cacheDir, registryRepo); err != nil {
			return fmt.Errorf("failed to clone registry: %w", err)
		}
	} else {
		if err := r.git.Pull(r.cacheDir); err != nil {
			if err := r.fs.RemoveAll(r.cacheDir); err != nil {
				return fmt.Errorf("failed to remove corrupted registry: %w", err)
			}

			if err := r.fs.MkdirAll(filepath.Dir(r.cacheDir), 0755); err != nil {
				return fmt.Errorf("failed to create cache directory: %w", err)
			}

			if err := r.git.PlainClone(r.cacheDir, registryRepo); err != nil {
				return fmt.Errorf("failed to re-clone registry: %w", err)
			}
		}
	}

	return r.loadThemes()
}

func (r *Registry) loadThemes() error {
	themesDir := filepath.Join(r.cacheDir, "themes")

	entries, err := afero.ReadDir(r.fs, themesDir)
	if err != nil {
		return fmt.Errorf("failed to read themes directory: %w", err)
	}

	r.themes = []Theme{}

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		themeDir := filepath.Join(themesDir, entry.Name())
		themeFile := filepath.Join(themeDir, "theme.json")

		data, err := afero.ReadFile(r.fs, themeFile)
		if err != nil {
			continue
		}

		var theme Theme
		if err := json.Unmarshal(data, &theme); err != nil {
			continue
		}

		if theme.ID == "" {
			theme.ID = entry.Name()
		}
		theme.SourceDir = entry.Name()

		previewPath := filepath.Join(themeDir, "preview.svg")
		if exists, _ := afero.Exists(r.fs, previewPath); exists {
			theme.PreviewPath = previewPath
		}

		r.themes = append(r.themes, theme)
	}

	return nil
}

func (r *Registry) List() ([]Theme, error) {
	if len(r.themes) == 0 {
		if err := r.Update(); err != nil {
			return nil, err
		}
	}

	return SortByFirstParty(r.themes), nil
}

func (r *Registry) Search(query string) ([]Theme, error) {
	allThemes, err := r.List()
	if err != nil {
		return nil, err
	}

	if query == "" {
		return allThemes, nil
	}

	return SortByFirstParty(FuzzySearch(query, allThemes)), nil
}

func (r *Registry) Get(idOrName string) (*Theme, error) {
	themes, err := r.List()
	if err != nil {
		return nil, err
	}

	for _, t := range themes {
		if t.ID == idOrName {
			return &t, nil
		}
	}

	for _, t := range themes {
		if t.Name == idOrName {
			return &t, nil
		}
	}

	return nil, fmt.Errorf("theme not found: %s", idOrName)
}

func (r *Registry) GetThemeSourcePath(themeID string) string {
	return filepath.Join(r.cacheDir, "themes", themeID, "theme.json")
}

func (r *Registry) GetThemeDir(themeID string) string {
	return filepath.Join(r.cacheDir, "themes", themeID)
}

func SortByFirstParty(themes []Theme) []Theme {
	return themes
}
