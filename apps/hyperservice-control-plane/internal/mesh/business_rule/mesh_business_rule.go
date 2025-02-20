package business_rule

import (
	"context"
	"fmt"
	"time"

	"hyperservice-control-plane/internal/mesh/infrastructure"
	"hyperservice-control-plane/utils"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// Function to check if Kuma Control Plane is responsive on port 5681
func WaitForMeshControlPlaneReadiness() error {
	fmt.Println("⏳ Checking if Kuma Control Plane is responsive...")
	// Retry logic for checking the pod status
	maxRetries := 10
	retryCount := 0

	// Loop to check pod readiness
	for retryCount < maxRetries {
		if err := utils.CheckService("http://localhost:5681"); err != nil {
			fmt.Errorf("Kuma Control Plane is not responsive: %w", err)
			break
		}
		fmt.Println("✅ Kuma Control Plane is responsive!")
	}
	return nil
}

// WaitForMeshControlPlaneLiveness checks the Kuma control plane pod and service readiness
func WaitForMeshControlPlaneLiveness(clusterName string) error {
	namespace := "kuma-system"
	// Get Kubernetes client
	clientset, err := infrastructure.GetKubernetesClientSet(clusterName)
	if err != nil {
		return err
	}

	// Retry logic for checking the pod status
	maxRetries := 10
	retryCount := 0

	// Loop to check pod readiness
	for retryCount < maxRetries {
		// Fetch the Kuma control plane pods
		pods, err := clientset.CoreV1().Pods(namespace).List(context.Background(), metav1.ListOptions{
			LabelSelector: "app=kuma-control-plane",
		})
		if err != nil {
			return fmt.Errorf("failed to get pods: %w", err)
		}

		if len(pods.Items) > 0 && pods.Items[0].Status.Phase == corev1.PodRunning {
			fmt.Println("✅ Kuma Control Plane pod is now Running!")
			break
		}

		// Increment retry count and print retry message
		retryCount++
		fmt.Printf("🔄 Kuma Control Plane pod is not ready yet. Retrying... (%d/%d)\n", retryCount, maxRetries)

		// If it's the last attempt, return error
		if retryCount == maxRetries {
			fmt.Println("❌ Reached maximum retry attempts for pod readiness.")
			return fmt.Errorf("Kuma Control Plane pod not ready after %d retries", maxRetries)
		}

		// Wait a bit before retrying
		time.Sleep(5 * time.Second)
	}

	// Retry logic for checking the service's active endpoints
	retryCount = 0
	for retryCount < maxRetries {
		// Fetch the Kuma control plane service endpoints
		endpoints, err := clientset.CoreV1().Endpoints(namespace).Get(context.Background(), "kuma-control-plane", metav1.GetOptions{})
		if err != nil {
			return fmt.Errorf("failed to get service endpoints: %w", err)
		}

		// Check if the service has active endpoints
		if len(endpoints.Subsets) > 0 && len(endpoints.Subsets[0].Addresses) > 0 {
			fmt.Println("✅ Kuma Control Plane service is now ready!")
			break
		}

		// Increment retry count and print retry message
		retryCount++
		fmt.Printf("🔄 Kuma Control Plane service does not have active endpoints yet. Retrying... (%d/%d)\n", retryCount, maxRetries)

		// If it's the last attempt, return error
		if retryCount == maxRetries {
			fmt.Println("❌ Reached maximum retry attempts for service readiness.")
			return fmt.Errorf("Kuma Control Plane service not ready after %d retries", maxRetries)
		}

		// Wait a bit before retrying
		time.Sleep(5 * time.Second)
	}

	return nil
}
