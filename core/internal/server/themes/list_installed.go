package themes

import (
	"fmt"
	"net"

	"github.com/AvengeMedia/DankMaterialShell/core/internal/server/models"
	"github.com/AvengeMedia/DankMaterialShell/core/internal/themes"
)

func addVariantsInfo(info *ThemeInfo, variants *themes.ThemeVariants) {
	if variants == nil || len(variants.Options) == 0 {
		return
	}
	info.HasVariants = true
	info.Variants = &VariantsInfo{
		Default: variants.Default,
		Options: make([]VariantInfo, len(variants.Options)),
	}
	for i, v := range variants.Options {
		info.Variants.Options[i] = VariantInfo{ID: v.ID, Name: v.Name}
	}
}

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

			info := ThemeInfo{
				ID:          theme.ID,
				Name:        theme.Name,
				Version:     theme.Version,
				Author:      theme.Author,
				Description: theme.Description,
				SourceDir:   id,
				FirstParty:  isFirstParty(theme.Author),
				HasUpdate:   hasUpdate,
			}
			addVariantsInfo(&info, theme.Variants)
			result = append(result, info)
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
			info := ThemeInfo{
				ID:          installed.ID,
				Name:        installed.Name,
				Version:     installed.Version,
				Author:      installed.Author,
				Description: installed.Description,
				SourceDir:   id,
				FirstParty:  isFirstParty(installed.Author),
			}
			addVariantsInfo(&info, installed.Variants)
			result = append(result, info)
		}
	}

	models.Respond(conn, req.ID, result)
}
