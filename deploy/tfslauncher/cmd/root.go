/*
Copyright © 2023 David Araújo

*/
package cmd

import (
	"os"

	"github.com/spf13/cobra"
)

var (
	tfs_registry_images string
	tfs_component string
)

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "tfslauncher",
	Short: "TeraFlowSDN Controller installer and launcher",
	Long: `A longer description that spans multiple lines and likely contains
examples and usage of using your application. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	// Uncomment the following line if your bare application
	// has an action associated with it:
	// Run: func(cmd *cobra.Command, args []string) { },
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func init() {
	// Here you will define your flags and configuration settings.
	// Cobra supports persistent flags, which, if defined here,
	// will be global for your application.

	// rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.tfslauncher.yaml)")

	// Cobra also supports local flags, which will only run
	// when this action is called directly.
	rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")

	rootCmd.Flags().StringVar("tfs-registry-images", "http://localhost:32000/tfs/", "If not already set, set the URL of the Docker registry where the images will be uploaded to. By default, assume internal MicroK8s registry is used.")

	rootCmd.Flags().StringSlice("tfs-component", "context device automation monitoring pathcomp service slice compute webui load_generator")
}


