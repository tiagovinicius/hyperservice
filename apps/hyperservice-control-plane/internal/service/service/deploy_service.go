package service

import (
	"fmt"
	"hyperservice-control-plane/internal/infrastructure"
	"hyperservice-control-plane/internal/service/model"
)

func DeployService(cluster []model.ClusterNode, deploymentName, namespace string) error {
	for _, node := range cluster {
		if !infrastructure.CheckK3dNodeExists(node.Name) {
			if err := infrastructure.CreateK3dNode(node.Name); err != nil {
				return fmt.Errorf("failed to create node %s: %w", node.Name, err)
			}
		}
	}
	return infrastructure.UpdateKubernetsDeploymentAffinity(deploymentName, namespace, extractNodeNames(cluster))
}

func extractNodeNames(cluster []model.ClusterNode) []string {
	names := []string{}
	for _, node := range cluster {
		names = append(names, node.Name)
	}
	return names
}
