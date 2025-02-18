package cmd

import (
	"log"
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "hyperservice-cli",
	Short: "Hyperservice CLI - A simple command line tool",
	Run: func(cmd *cobra.Command, args []string) {
		log.Println("Hello from hyperservice-cli!!!")
	},
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		log.Println(err)
		os.Exit(1)
	}
}