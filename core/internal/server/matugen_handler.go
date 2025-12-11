package server

import (
	"context"
	"net"
	"time"

	"github.com/AvengeMedia/DankMaterialShell/core/internal/matugen"
	"github.com/AvengeMedia/DankMaterialShell/core/internal/server/models"
)

type MatugenQueueResult struct {
	Success bool   `json:"success"`
	Message string `json:"message,omitempty"`
}

func handleMatugenQueue(conn net.Conn, req models.Request) {
	getString := func(key string) string {
		if v, ok := req.Params[key].(string); ok {
			return v
		}
		return ""
	}

	getBool := func(key string, def bool) bool {
		if v, ok := req.Params[key].(bool); ok {
			return v
		}
		return def
	}

	opts := matugen.Options{
		StateDir:            getString("stateDir"),
		ShellDir:            getString("shellDir"),
		ConfigDir:           getString("configDir"),
		Kind:                getString("kind"),
		Value:               getString("value"),
		Mode:                getString("mode"),
		IconTheme:           getString("iconTheme"),
		MatugenType:         getString("matugenType"),
		RunUserTemplates:    getBool("runUserTemplates", true),
		StockColors:         getString("stockColors"),
		SyncModeWithPortal:  getBool("syncModeWithPortal", false),
		TerminalsAlwaysDark: getBool("terminalsAlwaysDark", false),
		SkipTemplates:       getString("skipTemplates"),
	}

	wait := getBool("wait", true)

	queue := matugen.GetQueue()
	resultCh := queue.Submit(opts)

	if !wait {
		models.Respond(conn, req.ID, MatugenQueueResult{
			Success: true,
			Message: "queued",
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	select {
	case result := <-resultCh:
		if result.Error != nil {
			if result.Error == context.Canceled {
				models.Respond(conn, req.ID, MatugenQueueResult{
					Success: false,
					Message: "cancelled",
				})
				return
			}
			models.RespondError(conn, req.ID, result.Error.Error())
			return
		}
		models.Respond(conn, req.ID, MatugenQueueResult{
			Success: true,
			Message: "completed",
		})
	case <-ctx.Done():
		models.RespondError(conn, req.ID, "timeout waiting for theme generation")
	}
}

func handleMatugenStatus(conn net.Conn, req models.Request) {
	queue := matugen.GetQueue()
	models.Respond(conn, req.ID, map[string]bool{
		"running": queue.IsRunning(),
		"pending": queue.HasPending(),
	})
}
