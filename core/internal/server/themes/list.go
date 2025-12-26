package themes

import (
	"fmt"
	"net"
	"strings"

	"github.com/AvengeMedia/DankMaterialShell/core/internal/server/models"
	"github.com/AvengeMedia/DankMaterialShell/core/internal/themes"
)

func HandleList(conn net.Conn, req models.Request) {
	registry, err := themes.NewRegistry()
	if err != nil {
		models.RespondError(conn, req.ID, fmt.Sprintf("failed to create registry: %v", err))
		return
	}

	themeList, err := registry.List()
	if err != nil {
		models.RespondError(conn, req.ID, fmt.Sprintf("failed to list themes: %v", err))
		return
	}

	manager, err := themes.NewManager()
	if err != nil {
		models.RespondError(conn, req.ID, fmt.Sprintf("failed to create manager: %v", err))
		return
	}

	result := make([]ThemeInfo, len(themeList))
	for i, t := range themeList {
		installed, _ := manager.IsInstalled(t)
		info := ThemeInfo{
			ID:          t.ID,
			Name:        t.Name,
			Version:     t.Version,
			Author:      t.Author,
			Description: t.Description,
			PreviewPath: t.PreviewPath,
			SourceDir:   t.SourceDir,
			Installed:   installed,
			FirstParty:  isFirstParty(t.Author),
		}
		if t.Variants != nil && len(t.Variants.Options) > 0 {
			info.HasVariants = true
			info.Variants = &VariantsInfo{
				Default: t.Variants.Default,
				Options: make([]VariantInfo, len(t.Variants.Options)),
			}
			for j, v := range t.Variants.Options {
				info.Variants.Options[j] = VariantInfo{ID: v.ID, Name: v.Name}
			}
		}
		result[i] = info
	}

	models.Respond(conn, req.ID, result)
}

func isFirstParty(author string) bool {
	return strings.EqualFold(author, "Avenge Media") || strings.EqualFold(author, "AvengeMedia")
}
