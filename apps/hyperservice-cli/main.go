package main

import (
	rootCmd "hyperservice-cli/cmd"
	_ "hyperservice-cli/internal/mesh/cmd"
	_ "hyperservice-cli/internal/observability/cmd"
)

func main() {
	rootCmd.Execute()
}