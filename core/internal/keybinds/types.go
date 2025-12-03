package keybinds

type Keybind struct {
	Key         string `json:"key"`
	Description string `json:"desc"`
	Action      string `json:"action,omitempty"`
	Subcategory string `json:"subcat,omitempty"`
	Source      string `json:"source,omitempty"`
}

type CheatSheet struct {
	Title            string               `json:"title"`
	Provider         string               `json:"provider"`
	Binds            map[string][]Keybind `json:"binds"`
	DMSBindsIncluded bool                 `json:"dmsBindsIncluded"`
}

type Provider interface {
	Name() string
	GetCheatSheet() (*CheatSheet, error)
}

type WritableProvider interface {
	Provider
	SetBind(key, action, description string, options map[string]any) error
	RemoveBind(key string) error
	GetOverridePath() string
}
