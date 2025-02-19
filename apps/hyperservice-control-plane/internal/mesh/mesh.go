package mesh

// MeshRequest represents the body of the request for the /meshes/up endpoint.
type MeshRequest struct {
	Policies []string `json:"policies"`
}
