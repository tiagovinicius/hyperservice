package model

type ServiceStartRequest struct {
	Name      string            `json:"name"`
	Workdir   string            `json:"workdir"`
	Pod       *Pod              `json:"pod,omitempty"`
	Container *Container        `json:"container,omitempty"`
	Policies  *[]string         `json:"policies,omitempty"`
	Cluster   *[]string         `json:"cluster,omitempty"`
	EnvVars   map[string]string `json:"env,omitempty"`
}
