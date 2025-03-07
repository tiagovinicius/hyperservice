package model

type ServiceStartServeRequest struct {
	Name      string            `json:"name"`
	Pod       *Pod              `json:"pod,omitempty"`
	Build     bool              `json:"build,omitempty"`
	Workdir   string            `json:"workdir,omitempty"`
	Container *Container        `json:"container"`
	Policies  *[]string         `json:"policies,omitempty"`
	EnvVars   map[string]string `json:"env,omitempty"`
}
