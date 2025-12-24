package themes

type ThemeInfo struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Version     string `json:"version"`
	Author      string `json:"author,omitempty"`
	Description string `json:"description,omitempty"`
	PreviewPath string `json:"previewPath,omitempty"`
	SourceDir   string `json:"sourceDir,omitempty"`
	Installed   bool   `json:"installed,omitempty"`
	FirstParty  bool   `json:"firstParty,omitempty"`
	HasUpdate   bool   `json:"hasUpdate,omitempty"`
}
