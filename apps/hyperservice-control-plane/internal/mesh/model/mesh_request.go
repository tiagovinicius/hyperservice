package model

// MeshRequest represents the body of the request for the /meshes/up endpoint.
type MeshRequest struct {
	Policies []string      `json:"policies,omitempty"`
	Cluster  []ClusterNode `json:"cluster,omitempty"`
}
