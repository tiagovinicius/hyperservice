package application

import (
	"hyperservice-control-plane/internal/observability/service"
	"hyperservice-control-plane/utils"
)

func ObservabilityUpApplication() error {
	err := service.StartObservability()
	if err != nil {
		return utils.LogError("failed to start Grafana in mesh", err)
	}

	return nil
}
