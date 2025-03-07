package model

type K3dClusterConfig struct {
	APIVersion string      `yaml:"apiVersion"`
	Kind       string      `yaml:"kind"`
	Metadata   K3dMetadata `yaml:"metadata"`
	Servers    []K3dServer `yaml:"servers"`
	Agents     []K3dAgent  `yaml:"agents,omitempty"`
}
