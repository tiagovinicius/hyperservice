package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "hyperservice-cli",
	Short: "Hyperservice CLI - A simple command line tool",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Hello from hyperservice-cli!!!")
	},
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}