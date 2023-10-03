/*
Copyright © 2023 David Araújo
*/
package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	ViperConfs					= viper.New()
	registry_images              string
	component                    []string
	image_tag                    string
	k8s_namespace                string
	extra_manifests              string
	grafana_password             string
	skip_build                   bool
	crdb_namespace               string
	crdb_ext_port_sql            int
	crdb_ext_port_http           int
	crdb_username                string
	crdb_password                string
	crdb_database                string
	crdb_deploy_mode             string
	crdb_drop_database_if_exists bool
	crdb_redeploy                bool
	nats_namespace               string
	nats_ext_port_client         int
	nats_ext_port_http           int
	nats_redeploy                bool
	qdb_namespace                string
	qdb_ext_port_sql             int
	qdb_ext_port_ilp             int
	qdb_ext_port_http            int
	qdb_username                 string
	qdb_password                 string
	qdb_table_monitoring_kpis    string
	qdb_table_slice_groups       string
	qdb_drop_tables_if_exits     bool
	qdb_redeploy                 bool
	prom_ext_port_http           int
	grafana_ext_port_http        int
)

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "tfslauncher",
	Short: "TeraFlowSDN Controller installer and launcher",
	Run: func(cmd *cobra.Command, args []string) {
		// If no flag is set, prints help message
		if cmd.Flags().NFlag() == 0 {
			cmd.Help()
            os.Exit(0)
		}
	},
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

	var configfilepath = rootCmd.Flags().StringP("file", "f", "./tfs-config.yaml", "configuration file with TFS environment variables")
	if *configfilepath != "" {
		exists, _ := Exists(*configfilepath)
		if !exists {
			panic(fmt.Errorf("configuration file not found"))
		}
		path, name := filepath.Split(*configfilepath)
		ViperConfs.AddConfigPath(path)
		ViperConfs.SetConfigName(strings.TrimSuffix(name, filepath.Ext(name)))
		ViperConfs.SetConfigType("yaml")
		ViperConfs.ReadInConfig()
	}

	// TFS variables
	rootCmd.Flags().StringVar(&registry_images, "registry-images", "http://localhost:32000/tfs/", "the URL of the Docker registry where the images will be uploaded to. By default, assume internal MicroK8s registry is used")
	ViperConfs.BindPFlag("tfs.registry-images", rootCmd.Flags().Lookup("registry-images"))

	rootCmd.Flags().StringArrayVar(&component, "component", []string{"context", "device", "automation", "monitoring", "pathcomp", "service", "slice", "compute", "webui", "load_generator"}, "the list of components, separated by spaces, you want to build images for, and deploy. By default, only basic components are deployed")
	ViperConfs.BindPFlag("tfs.component", rootCmd.Flags().Lookup("component"))

	rootCmd.Flags().StringVar(&image_tag, "image-tag", "dev", "the tag you want to use for your images")
	ViperConfs.BindPFlag("tfs.image-tag", rootCmd.Flags().Lookup("image-tag"))

	rootCmd.Flags().StringVar(&k8s_namespace, "k8s-namespace", "tfs", "the name of the Kubernetes namespace to deploy TFS to")
	ViperConfs.BindPFlag("tfs.k8s-namespace", rootCmd.Flags().Lookup("k8s-namespace"))

	rootCmd.Flags().StringVar(&extra_manifests, "extra-manifests", "", "additional manifest files to be applied after the deployment")
	ViperConfs.BindPFlag("tfs.extra-manifests", rootCmd.Flags().Lookup("extra-manifests"))

	rootCmd.Flags().StringVar(&grafana_password, "grafana-password", "admin123+", "the new Grafana admin password")
	ViperConfs.BindPFlag("tfs.grafana-password", rootCmd.Flags().Lookup("grafana-password"))

	rootCmd.Flags().BoolVar(&skip_build, "skip-build", false, "disable skip-build flag to rebuild the Docker images,  containers are not rebuilt-retagged-repushed and existing ones are used")
	ViperConfs.BindPFlag("tfs.skip-build", rootCmd.Flags().Lookup("skip-build"))

	// CockroachDB variables

	rootCmd.Flags().StringVar(&crdb_namespace, "crdb-namespace", "crdb", "the namespace where CockroackDB will be deployed")
	ViperConfs.BindPFlag("crdb.namespace", rootCmd.Flags().Lookup("crdb-namespace"))

	rootCmd.Flags().IntVar(&crdb_ext_port_sql, "crdb-ext-port-sql", 26257, "the external port CockroackDB Postgre SQL interface will be exposed to")
	ViperConfs.BindPFlag("crdb.external-ports.sql", rootCmd.Flags().Lookup("crdb-ext-port-sql"))

	rootCmd.Flags().IntVar(&crdb_ext_port_http, "crdb-ext-port-http", 8081, "the external port CockroackDB HTTP Mgmt GUI interface will be exposed to")
	ViperConfs.BindPFlag("crdb.external-ports.http", rootCmd.Flags().Lookup("crdb-ext-port-http"))

	rootCmd.Flags().StringVar(&crdb_username, "crdb-username", "tfs", "the database username to be used by Context")
	ViperConfs.BindPFlag("crdb.credentials.username", rootCmd.Flags().Lookup("crdb-username"))

	rootCmd.Flags().StringVar(&crdb_password, "crdb-password", "tfs123", "the database user's password to be used by Context")
	ViperConfs.BindPFlag("crdb.credentials.password", rootCmd.Flags().Lookup("crdb-password"))

	rootCmd.Flags().StringVar(&crdb_database, "crdb-database", "tfs+", "the database name to be used by Context")
	ViperConfs.BindPFlag("crdb.database", rootCmd.Flags().Lookup("crdb-database"))

	rootCmd.Flags().StringVar(&crdb_deploy_mode, "crdb-deploy-mode", "single", "CockroachDB installation mode. Accepted values are: 'single' and 'cluster'")
	ViperConfs.BindPFlag("crdb.deploy-mode", rootCmd.Flags().Lookup("crdb-deploy-mode"))

	rootCmd.Flags().BoolVar(&crdb_drop_database_if_exists, "crdb-drop-database", false, "the database pointed by variable CRDB_NAMESPACE will be dropped while checking/deploying CockroachDB")
	ViperConfs.BindPFlag("crdb.drop-database", rootCmd.Flags().Lookup("crdb-drop-database"))

	rootCmd.Flags().BoolVar(&crdb_redeploy, "crdb-redeploy", false, "the database will be dropped while checking/deploying CockroachDB")
	ViperConfs.BindPFlag("crdb.redeploy", rootCmd.Flags().Lookup("crdb-redeploy"))

	// NATS variables

	rootCmd.Flags().StringVar(&nats_namespace, "nats-namespace", "nats", "the namespace where NATS will be deployed")
	ViperConfs.BindPFlag("nats.namespace", rootCmd.Flags().Lookup("nats-namespace"))

	rootCmd.Flags().IntVar(&nats_ext_port_client, "nats-ext-port-client", 4222, "the external port NATS Client interface will be exposed to")
	ViperConfs.BindPFlag("nats.external-ports.client", rootCmd.Flags().Lookup("nats-ext-port-client"))

	rootCmd.Flags().IntVar(&nats_ext_port_http, "nats-ext-port-http", 8222, "the external port NATS HTTP Mgmt GUI interface will be exposed to")
	ViperConfs.BindPFlag("nats.external-ports.http", rootCmd.Flags().Lookup("nats-ext-port-http"))

	rootCmd.Flags().BoolVar(&nats_redeploy, "nats-redeploy", false, "the message broker will be dropped while checking/deploying NATS")
	ViperConfs.BindPFlag("nats.redeploy", rootCmd.Flags().Lookup("nats-redeploy"))

	// QuestDB variables

	rootCmd.Flags().StringVar(&qdb_namespace, "qdb-namespace", "qdb", "the namespace where QuestDB will be deployed")
	ViperConfs.BindPFlag("qdb.namespace", rootCmd.Flags().Lookup("qdb-namespace"))

	rootCmd.Flags().IntVar(&qdb_ext_port_sql, "qdb-ext-port-sql", 8812, "the external port QuestDB Postgre SQL interface will be exposed to")
	ViperConfs.BindPFlag("qdb.external-ports.sql", rootCmd.Flags().Lookup("ext_port_sql"))

	rootCmd.Flags().IntVar(&qdb_ext_port_ilp, "qdb-ext-port-ilp", 9009, "the external port QuestDB Influx Line Protocol interface will be exposed to")
	ViperConfs.BindPFlag("qdb.external-ports.ilp", rootCmd.Flags().Lookup("qdb-ext_port_ilp"))

	rootCmd.Flags().IntVar(&qdb_ext_port_http, "qdb-ext-port-http", 9000, "the external port QuestDB HTTP Mgmt GUI interface will be exposed to")
	ViperConfs.BindPFlag("qdb.external-ports.http", rootCmd.Flags().Lookup("qdb-ext_port_http"))

	rootCmd.Flags().StringVar(&qdb_username, "qdb-username", "admin", "the database username to be used for QuestDB")
	ViperConfs.BindPFlag("qdb.credentials.username", rootCmd.Flags().Lookup("qdb-username"))

	rootCmd.Flags().StringVar(&qdb_password, "qdb-password", "quest", "the database user's password to be used for QuestDB")
	ViperConfs.BindPFlag("qdb.credentials.password", rootCmd.Flags().Lookup("qdb-password"))

	rootCmd.Flags().StringVar(&qdb_table_monitoring_kpis, "qdb-table-monitoring", "tfs_monitoring_kpis", "the table name to be used by Monitoring for KPIs")
	ViperConfs.BindPFlag("qdb.tables.monitoring-kpis", rootCmd.Flags().Lookup("qdb-table-monitoring"))

	rootCmd.Flags().StringVar(&qdb_table_slice_groups, "qdb-table-slice", "tfs_slice_groups", "the table name to be used by Slice for plotting groups")
	ViperConfs.BindPFlag("qdb.tables.slice-groups", rootCmd.Flags().Lookup("qdb-table-slice"))

	rootCmd.Flags().BoolVar(&qdb_drop_tables_if_exits, "qdb-drop-table", false, "the tables pointed by variables QDB_TABLE_MONITORING_KPIS and QDB_TABLE_SLICE_GROUPS will be dropped while checking/deploying QuestDB")
	ViperConfs.BindPFlag("qdb.tables.drop-if-exits", rootCmd.Flags().Lookup("qdb-drop-table"))

	rootCmd.Flags().BoolVar(&qdb_redeploy, "qdb-redeploy", false, "the database will be dropped while checking/deploying QuestDB")
	ViperConfs.BindPFlag("qdb.redeploy", rootCmd.Flags().Lookup("qdb-redeploy"))

	// K8s Observability variables

	rootCmd.Flags().IntVar(&prom_ext_port_http, "prom-ext-port-http", 9090, "he external port Prometheus Mgmt HTTP GUI interface will be exposed to")
	ViperConfs.BindPFlag("service-ports.prometheus-http", rootCmd.Flags().Lookup("prom-ext-port-http"))

	rootCmd.Flags().IntVar(&grafana_ext_port_http, "graf-ext-port-http", 3000, "the external port Grafana HTTP Dashboards will be exposed to")
	ViperConfs.BindPFlag("service-ports.grafana-http", rootCmd.Flags().Lookup("graf-ext-port-http"))
}

func Exists(path string) (bool, error) {
	_, err := os.Stat(path)
	if err == nil {
		return true, nil
	}
	return false, err
}