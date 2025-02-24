package main

import (
	rootCmd "hyperservice-cli/cmd"
	_ "hyperservice-cli/internal/mesh/cmd"
)

func main() {
	rootCmd.Execute()
}