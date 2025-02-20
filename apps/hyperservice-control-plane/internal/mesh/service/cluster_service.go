package service

import (
	"fmt"
	"strings"

	"hyperservice-control-plane/internal/mesh/business_rule"
)

// StartCluster creates a k3d cluster and connects it to the Registry using the K3D binary
func StartCluster(clusterName string) error {
	// Remove old clusters to avoid conflicts
	existingCluster, err := business_rule.GetExistingClusters()
	if err != nil {
		fmt.Println("✅ No cluster found!")
	}

	if len(existingCluster) > 0 {
		fmt.Printf("⚠️ Found existing clusters: %s\n", strings.Join(existingCluster, ", "))
		for _, cluster := range existingCluster {
			if cluster == clusterName {
				fmt.Printf("🛑 Deleting cluster '%s'...\n", cluster)
				if err := business_rule.DeleteCluster(cluster); err != nil {
					return err
				}
				fmt.Printf("✅ Cluster '%s' deleted!\n", cluster)
			}
		}
		fmt.Println("✅ Checked for existing clusters, deletion complete!")
	}

	// Ensure the volume exists before creating the cluster
	if err := business_rule.EnsureVolumeExists("hyperservice-grafana-data"); err != nil {
		return err
	}

	// Create K3D cluster using the K3D binary
	fmt.Printf("⏳ Creating K3s cluster '%s'...\n", clusterName)
	if err := business_rule.CreateCluster(clusterName); err != nil {
		return err
	}
	fmt.Printf("✅ Cluster k3d '%s' created successfully!\n", clusterName)


	// Create application-specific namespace
	fmt.Printf("⚙️ Creating '%s' namespace...\n", clusterName)
	if err := business_rule.CreateApplicationsNamespace(clusterName, clusterName); err != nil {
		return err
	}

	return nil
}
