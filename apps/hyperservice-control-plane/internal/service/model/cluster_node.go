package model

type ClusterNode struct {
	Name      string           `json:"name"`
	Simulate  bool             `json:"simulate,omitempty"`
	Container *Container       `json:"container,omitempty"`
	Auth      *AuthCredentials `json:"auth,omitempty"`
}
