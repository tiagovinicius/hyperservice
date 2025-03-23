package service

import (
	"hyperservice-control-plane/internal/infrastructure"
	"log"
)

func DeployService(serviceName string, cluster []string) error {

	clientset, err := infrastructure.GetKubernetesClientSet("hyperservice")
	if err != nil {
		return err
	}
	var formattedCluster []string
	for _, node := range cluster {
		formattedCluster = append(formattedCluster, "k3d-hyperservice-"+node+"-0")
	}
	log.Println("Formatted nodes:", formattedCluster)
	return infrastructure.LabelNodesForService(clientset, serviceName, formattedCluster)
}
