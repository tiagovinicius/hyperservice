package model

type K3dAgent struct {
	Name  string `yaml:"name"`
	Image string `yaml:"image,omitempty"`
}
