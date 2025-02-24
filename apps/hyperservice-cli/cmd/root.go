package cmd

import (
	"fmt"
	"hyperservice-cli/internal/utils"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
)

var Workdir string // Base directory

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "hyperservice-cli",
	Short: "Hyperservice CLI for managing the system",
	Long:  `A command-line tool to interact with the Hyperservice ecosystem.`,
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
		// If --workdir flag is not provided, use the current directory
		if Workdir == "" {
			execDir, err := os.Getwd()
			if err != nil {
				fmt.Println("❌ Error: Unable to determine the working directory.")
				os.Exit(1)
			}
			Workdir = execDir
		}

		// Convert to an absolute path
		absPath, err := filepath.Abs(Workdir)
		if err != nil {
			fmt.Println("❌ Error: Invalid workdir path.")
			os.Exit(1)
		}
		Workdir = absPath

		// Check if we are in a valid hyperservice workspace
		utils.CheckWorkspace(Workdir)
	},
}

// GetWorkdir returns the current workdir
func GetWorkdir() string {
	return Workdir
}

// GetRootCmd returns the root command for registering subcommands
func GetRootCmd() *cobra.Command {
	return rootCmd
}

// Execute adds all child commands to the root command and sets flags appropriately.
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println("❌ Error:", err)
		os.Exit(1)
	}
}

func init() {
	// Add global flag --workdir
	rootCmd.PersistentFlags().StringVarP(&Workdir, "workdir", "w", "", "Base directory for execution (default: current directory)")
}