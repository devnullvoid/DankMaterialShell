package themes

import (
	"fmt"
	"net"

	"github.com/AvengeMedia/DankMaterialShell/core/internal/server/models"
	"github.com/AvengeMedia/DankMaterialShell/core/internal/themes"
)

func HandleListInstalled(conn net.Conn, req models.Request) {
	manager, err := themes.NewManager()
	if err != nil {
		models.RespondError(conn, req.ID, fmt.Sprintf("failed to create manager: %v", err))
		return
	}

	installedIDs, err := manager.ListInstalled()
	if err != nil {
		models.RespondError(conn, req.ID, fmt.Sprintf("failed to list installed themes: %v", err))
		return
	}

	registry, err := themes.NewRegistry()
	if err != nil {
		models.RespondError(conn, req.ID, fmt.Sprintf("failed to create registry: %v", err))
		return
	}

	allThemes, err := registry.List()
	if err != nil {
		models.RespondError(conn, req.ID, fmt.Sprintf("failed to list themes: %v", err))
		return
	}

	themeMap := make(map[string]themes.Theme)
	for _, t := range allThemes {
		themeMap[t.ID] = t
	}

	result := make([]ThemeInfo, 0, len(installedIDs))
	for _, id := range installedIDs {
		if theme, ok := themeMap[id]; ok {
			hasUpdate := false
			if hasUpdates, err := manager.HasUpdates(id, theme); err == nil {
				hasUpdate = hasUpdates
			}

			result = append(result, ThemeInfo{
				ID:          theme.ID,
				Name:        theme.Name,
				Version:     theme.Version,
				Author:      theme.Author,
				Description: theme.Description,
				SourceDir:   id,
				FirstParty:  isFirstParty(theme.Author),
				HasUpdate:   hasUpdate,
			})
		} else {
			installed, err := manager.GetInstalledTheme(id)
			if err != nil {
				result = append(result, ThemeInfo{
					ID:        id,
					Name:      id,
					SourceDir: id,
				})
				continue
			}
			result = append(result, ThemeInfo{
				ID:          installed.ID,
				Name:        installed.Name,
				Version:     installed.Version,
				Author:      installed.Author,
				Description: installed.Description,
				SourceDir:   id,
				FirstParty:  isFirstParty(installed.Author),
			})
		}
	}

	models.Respond(conn, req.ID, result)
}
