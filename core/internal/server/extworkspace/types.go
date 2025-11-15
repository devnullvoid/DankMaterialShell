package extworkspace

import (
	"sync"

	"github.com/AvengeMedia/DankMaterialShell/core/internal/proto/ext_workspace"
	wlclient "github.com/AvengeMedia/DankMaterialShell/core/pkg/go-wayland/wayland/client"
)

type Workspace struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Coordinates []uint32 `json:"coordinates"`
	State       uint32   `json:"state"`
	Active      bool     `json:"active"`
	Urgent      bool     `json:"urgent"`
	Hidden      bool     `json:"hidden"`
}

type WorkspaceGroup struct {
	ID         string       `json:"id"`
	Outputs    []string     `json:"outputs"`
	Workspaces []*Workspace `json:"workspaces"`
}

type State struct {
	Groups []*WorkspaceGroup `json:"groups"`
}

type cmd struct {
	fn func()
}

type Manager struct {
	display  *wlclient.Display
	ctx      *wlclient.Context
	registry *wlclient.Registry
	manager  *ext_workspace.ExtWorkspaceManagerV1

	outputsMutex sync.RWMutex
	outputs      map[uint32]*wlclient.Output
	outputNames  map[uint32]string

	groupsMutex sync.RWMutex
	groups      map[uint32]*workspaceGroupState

	workspacesMutex sync.RWMutex
	workspaces      map[uint32]*workspaceState

	wlMutex  sync.Mutex
	cmdq     chan cmd
	stopChan chan struct{}
	wg       sync.WaitGroup

	subscribers  sync.Map
	dirty        chan struct{}
	notifierWg   sync.WaitGroup
	lastNotified *State

	stateMutex sync.RWMutex
	state      *State
}

type workspaceGroupState struct {
	id           uint32
	handle       *ext_workspace.ExtWorkspaceGroupHandleV1
	outputIDs    map[uint32]bool
	workspaceIDs []uint32
	removed      bool
}

type workspaceState struct {
	id          uint32
	handle      *ext_workspace.ExtWorkspaceHandleV1
	workspaceID string
	name        string
	coordinates []uint32
	state       uint32
	groupID     uint32
	removed     bool
}

func (m *Manager) GetState() State {
	m.stateMutex.RLock()
	defer m.stateMutex.RUnlock()
	if m.state == nil {
		return State{
			Groups: []*WorkspaceGroup{},
		}
	}
	stateCopy := *m.state
	return stateCopy
}

func (m *Manager) Subscribe(id string) chan State {
	ch := make(chan State, 64)

	m.subscribers.Store(id, ch)

	return ch
}

func (m *Manager) Unsubscribe(id string) {

	if val, ok := m.subscribers.LoadAndDelete(id); ok {
		close(val.(chan State))

	}

}

func (m *Manager) notifySubscribers() {
	select {
	case m.dirty <- struct{}{}:
	default:
	}
}

func stateChanged(old, new *State) bool {
	if old == nil || new == nil {
		return true
	}
	if len(old.Groups) != len(new.Groups) {
		return true
	}

	for i, newGroup := range new.Groups {
		if i >= len(old.Groups) {
			return true
		}
		oldGroup := old.Groups[i]
		if oldGroup.ID != newGroup.ID {
			return true
		}
		if len(oldGroup.Outputs) != len(newGroup.Outputs) {
			return true
		}
		for j, newOutput := range newGroup.Outputs {
			if j >= len(oldGroup.Outputs) {
				return true
			}
			if oldGroup.Outputs[j] != newOutput {
				return true
			}
		}
		if len(oldGroup.Workspaces) != len(newGroup.Workspaces) {
			return true
		}
		for j, newWs := range newGroup.Workspaces {
			if j >= len(oldGroup.Workspaces) {
				return true
			}
			oldWs := oldGroup.Workspaces[j]
			if oldWs.ID != newWs.ID || oldWs.Name != newWs.Name || oldWs.State != newWs.State {
				return true
			}
			if oldWs.Active != newWs.Active || oldWs.Urgent != newWs.Urgent || oldWs.Hidden != newWs.Hidden {
				return true
			}
			if len(oldWs.Coordinates) != len(newWs.Coordinates) {
				return true
			}
			for k, coord := range newWs.Coordinates {
				if k >= len(oldWs.Coordinates) {
					return true
				}
				if oldWs.Coordinates[k] != coord {
					return true
				}
			}
		}
	}

	return false
}
