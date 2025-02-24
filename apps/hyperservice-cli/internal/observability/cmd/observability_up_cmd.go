package cmd

import (
	"fmt"
	"hyperservice-cli/internal/observability/request"

	"github.com/spf13/cobra"
)

// observabilityUpCmd represents the `observability up` command
var observabilityUpCmd = &cobra.Command{
	Use:   "up",
	Short: "Start observability services",
	RunE: func(cmd *cobra.Command, args []string) error {
		if err := request.ObservabilityUpRequest(); err != nil {
			return err
		}
		fmt.Println("✅ Observability services successfully scheduled to up!")
		return nil
	},
}

func init() {
	GetObservabilityCmd().AddCommand(observabilityUpCmd) // Ensure it registers under meshCmd
}