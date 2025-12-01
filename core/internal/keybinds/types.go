package keybinds

type Keybind struct {
	Key         string `json:"key"`
	Description string `json:"desc"`
	Action      string `json:"action,omitempty"`
	Subcategory string `json:"subcat,omitempty"`
}

type CheatSheet struct {
	Title    string               `json:"title"`
	Provider string               `json:"provider"`
	Binds    map[string][]Keybind `json:"binds"`
}

type Provider interface {
	Name() string
	GetCheatSheet() (*CheatSheet, error)
}
