package service

import (
	"hyperservice-control-plane/internal/infrastructure"
)

func DeployService(serviceName string, cluster []string) error {

	clientset, err := infrastructure.GetKubernetesClientSet("hyperservice")
	if err != nil {
		return err
	}
	return infrastructure.LabelNodesForService(clientset, serviceName, cluster)
}
