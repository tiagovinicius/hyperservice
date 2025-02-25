package main

import (
	rootCmd "hyperservice-cli/cmd"
	_ "hyperservice-cli/internal/mesh/cmd"
	_ "hyperservice-cli/internal/observability/cmd"
	_ "hyperservice-cli/internal/service/cmd"
)

func main() {
	rootCmd.Execute()
}
