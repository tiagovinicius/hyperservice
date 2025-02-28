package business_rule

import (
	"context"
	"fmt"
	"time"

	"hyperservice-control-plane/internal/infrastructure"
	"hyperservice-control-plane/utils"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)


func WaitForObservabilityReadiness() error {
	fmt.Println("⏳ Checking if Grafana is responsive...")
	maxRetries := 10

	retryCount := 0
	for retryCount < maxRetries {
		if err := utils.CheckService("http://localhost:3000"); err != nil {
			fmt.Errorf("Grafana is not responsive: %w", err)
		}
		fmt.Println("✅ Grafana is responsive!")
		break
	}

	retryCount = 0
	for retryCount < maxRetries {
		if err := utils.CheckService("http://localhost:9090"); err != nil {
			fmt.Errorf("Prometheus is not responsive: %w", err)
		}
		fmt.Println("✅ Prometheus is responsive!")
		break
	}

	return nil
}

func WaitForObservabilityLiveness(clusterName string) error {
	namespace := "mesh-observability"
	clientset, err := infrastructure.GetKubernetesClientSet(clusterName)
	if err != nil {
		return err
	}

	maxRetries := 20

	retryCount := 0
	for retryCount < maxRetries {
		pods, err := clientset.CoreV1().Pods(namespace).List(context.Background(), metav1.ListOptions{
			LabelSelector: "app.kubernetes.io/name=grafana",
		})
		if err != nil {
			return fmt.Errorf("failed to get pods: %w", err)
		}

		if len(pods.Items) > 0 && pods.Items[0].Status.Phase == corev1.PodRunning {
			fmt.Println("✅ Grafana pod is now Running!")
			break
		}

		// Increment retry count and print retry message
		retryCount++
		fmt.Printf("🔄 Grafana pod is not ready yet. Retrying... (%d/%d)\n", retryCount, maxRetries)

		// If it's the last attempt, return error
		if retryCount == maxRetries {
			fmt.Println("❌ Reached maximum retry attempts for pod readiness.")
			return fmt.Errorf("Grafana pod not ready after %d retries", maxRetries)
		}

		// Wait a bit before retrying
		time.Sleep(5 * time.Second)
	}

	// Retry logic for checking the service's active endpoints
	retryCount = 0
	for retryCount < maxRetries {
		// Fetch the Grafana service endpoints
		endpoints, err := clientset.CoreV1().Endpoints(namespace).Get(context.Background(), "grafana", metav1.GetOptions{})
		if err != nil {
			return fmt.Errorf("failed to get service endpoints: %w", err)
		}

		// Check if the service has active endpoints
		if len(endpoints.Subsets) > 0 && len(endpoints.Subsets[0].Addresses) > 0 {
			fmt.Println("✅ Grafana service is now ready!")
			break
		}

		// Increment retry count and print retry message
		retryCount++
		fmt.Printf("🔄 Grafana service does not have active endpoints yet. Retrying... (%d/%d)\n", retryCount, maxRetries)

		// If it's the last attempt, return error
		if retryCount == maxRetries {
			fmt.Println("❌ Reached maximum retry attempts for service readiness.")
			return fmt.Errorf("Grafana service not ready after %d retries", maxRetries)
		}

		// Wait a bit before retrying
		time.Sleep(5 * time.Second)
	}





	retryCount = 0
	for retryCount < maxRetries {
		pods, err := clientset.CoreV1().Pods(namespace).List(context.Background(), metav1.ListOptions{
			LabelSelector: "app.kubernetes.io/name=prometheus",
		})
		if err != nil {
			return fmt.Errorf("failed to get pods: %w", err)
		}

		if len(pods.Items) > 0 && pods.Items[0].Status.Phase == corev1.PodRunning {
			fmt.Println("✅ prometheus pod is now Running!")
			break
		}

		// Increment retry count and print retry message
		retryCount++
		fmt.Printf("🔄 prometheus pod is not ready yet. Retrying... (%d/%d)\n", retryCount, maxRetries)

		// If it's the last attempt, return error
		if retryCount == maxRetries {
			fmt.Println("❌ Reached maximum retry attempts for pod readiness.")
			return fmt.Errorf("prometheus pod not ready after %d retries", maxRetries)
		}

		// Wait a bit before retrying
		time.Sleep(5 * time.Second)
	}

	// Retry logic for checking the service's active endpoints
	retryCount = 0
	for retryCount < maxRetries {
		// Fetch the prometheus service endpoints
		endpoints, err := clientset.CoreV1().Endpoints(namespace).Get(context.Background(), "prometheus", metav1.GetOptions{})
		if err != nil {
			return fmt.Errorf("failed to get service endpoints: %w", err)
		}

		// Check if the service has active endpoints
		if len(endpoints.Subsets) > 0 && len(endpoints.Subsets[0].Addresses) > 0 {
			fmt.Println("✅ prometheus service is now ready!")
			break
		}

		// Increment retry count and print retry message
		retryCount++
		fmt.Printf("🔄 prometheus service does not have active endpoints yet. Retrying... (%d/%d)\n", retryCount, maxRetries)

		// If it's the last attempt, return error
		if retryCount == maxRetries {
			fmt.Println("❌ Reached maximum retry attempts for service readiness.")
			return fmt.Errorf("prometheus service not ready after %d retries", maxRetries)
		}

		// Wait a bit before retrying
		time.Sleep(5 * time.Second)
	}

	return nil
}
