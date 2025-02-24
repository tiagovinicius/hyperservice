package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"

	rootCmd "hyperservice-cli/cmd"
	"hyperservice-cli/internal/mesh/request"
	"hyperservice-cli/internal/utils"
)

// MeshUpCmd represents the "mesh up" command
var meshUpCmd = &cobra.Command{
	Use:   "up",
	Short: "Brings up a mesh with optional policies",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🚀 Bringing up the mesh...")

		// Get workdir from root
		workdir := rootCmd.GetWorkdir()

		// Read policies from the optional directory
		policies, err := utils.ReadPoliciesFromDir(workdir)
		if err != nil {
			fmt.Printf("❌ Error: %v\n", err)
			os.Exit(1)
		}

		// Send the request to bring up the mesh
		if err := request.MeshUpRequest(policies); err != nil {
			fmt.Printf("❌ Error: %v\n", err)
			os.Exit(1)
		}
	},
}

func init() {
	GetMeshCmd().AddCommand(meshUpCmd) // Ensure it registers under meshCmd
}