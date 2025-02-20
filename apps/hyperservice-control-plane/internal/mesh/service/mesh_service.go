package service

import (
	"fmt"

	"hyperservice-control-plane/internal/mesh/business_rule"
	"hyperservice-control-plane/internal/mesh/infrastructure"
	"hyperservice-control-plane/utils"
)

// StartCluster creates a k3d cluster and connects it to the Registry using the K3D binary
func StartMesh(clusterName string) error {
	// Wait for Kuma Control Plane to be live
	fmt.Println("⏳ Checking if Kuma Control Plane is live...")
	if err := business_rule.WaitForClusterReadiness(clusterName); err != nil {
		fmt.Printf("Error checking Cluter liveness: %v\n", err)
		return err
	}

	fmt.Printf("⚙️ Creating '%s' namespace...\n", clusterName)
	if err := business_rule.CreateApplicationsNamespace(clusterName, "kuma-system"); err != nil {
		return err
	}

	// Install Kuma in 'kuma-system' namespace using Helm
	fmt.Println("🔄 Installing Kuma in namespace 'kuma-system'...")
	if err := utils.RunCommand("helm", "install", "kuma", "--namespace", "kuma-system", "./offline-dependencies/helm_chart/kuma"); err != nil {
		return err
	}

	// Wait for Kuma Control Plane to be live
	fmt.Println("⏳ Checking if Kuma Control Plane is live...")
	if err := business_rule.WaitForMeshControlPlaneLiveness(clusterName); err != nil {
		fmt.Printf("Error checking Kuma readiness: %v\n", err)
		return err
	}

	fmt.Println("🚀 Forwarding Kuma Control Plane on port 5681...")
	if err := infrastructure.MakeKubernetesPortForward("kuma-system", "kuma-control-plane", "5681", ":5681"); err != nil {
		return err
	}

	// Wait for Kuma Control Plane to be ready
	fmt.Println("⏳ Checking if Kuma Control Plane is ready...")
	if err := business_rule.WaitForMeshControlPlaneReadiness(); err != nil {
		fmt.Printf("Error checking Kuma readiness: %v\n", err)
		return err
	}

	return nil
}
