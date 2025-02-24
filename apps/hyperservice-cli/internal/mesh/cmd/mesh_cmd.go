package cmd

import (
	rootCmd "hyperservice-cli/cmd" // Import root command to register `meshCmd`

	"github.com/spf13/cobra"
)

// meshCmd represents the base command for mesh-related operations
var meshCmd = &cobra.Command{
	Use:   "mesh",
	Short: "Manage service meshes",
}

func init() {
	rootCmd.GetRootCmd().AddCommand(meshCmd) // Register under rootCmd
}

// GetMeshCmd returns the mesh command
func GetMeshCmd() *cobra.Command {
	return meshCmd
}