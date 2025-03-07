package model

type K3dServer struct {
	Name  string `yaml:"name"`
	Image string `yaml:"image,omitempty"`
}
