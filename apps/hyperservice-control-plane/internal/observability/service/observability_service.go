package service

import (
	"fmt"
	"hyperservice-control-plane/internal/mesh/infrastructure"
	business_rule "hyperservice-control-plane/internal/observability/busines_rule"
	"os"
)

func StartObservability() error {
	_, err := infrastructure.GetKubernetesClientSet("hyperservice")
	if err != nil {
		return err
	}

	namespace := "mesh-observability"
	configPath := os.Getenv("HY_CP_CONFIG")
	if configPath == "" {
		configPath = "/etc/hy-cp"
	}

	// Applying the Grafana Manifest
	fmt.Println("🚀 Applying Grafana Manifest...")
	infrastructure.RunKubernetsCommand("apply", "-f", configPath+"/manifests/observability/deploy.yml")

	// Triggering a rolling update to apply the label and restart pods
	fmt.Println("🔄 Triggering a rolling update for the deployment...")
	infrastructure.RunKubernetsCommand("rollout", "restart", "deployment", "grafana", "-n", namespace)

	business_rule.WaitForObservabilityLiveness("hyperservice")

	fmt.Println("🚀 Forwarding Grafana on port 3000...")
	if err := infrastructure.MakeKubernetesPortForward(namespace, "grafana", "3000", "80"); err != nil {
		return err
	}
	fmt.Println("🚀 Forwarding Prometheus on port 9090...")
	if err := infrastructure.MakeKubernetesPortForward(namespace, "prometheus", "9090", "80"); err != nil {
		return err
	}

	business_rule.WaitForObservabilityReadiness()

	if err := infrastructure.ApplyKubernetesManifestsDir(configPath+"/manifests/observability/policies", map[string]string{}); err != nil {
		fmt.Printf("Error: %v\n", err)
	}

	return nil
}
