package model

// ClusterNode defines the methods required for a cluster node
type ClusterNode interface {
	GetName() string
	GetImage() string
	GetSimulate() bool
}
