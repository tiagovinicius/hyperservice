package model

type ClusterNode struct {
	Name      string           `json:"name"`
	Simulate  bool             `json:"simulate,omitempty"`
	Container *Container       `json:"container,omitempty"`
	Auth      *AuthCredentials `json:"auth,omitempty"`
}

func (c *ClusterNode) GetName() string {
	return c.Name
}

func (c *ClusterNode) GetImage() string {
	if c.Container != nil {
		return c.Container.Image
	}
	return ""
}

func (c *ClusterNode) GetSimulate() bool {
	return c.Simulate
}
