import argparse

#def main():
    # TODO create namespace from variables
    # TODO Load yamls
    # TODO Edit yamls with variables
    # TODO Apply resources.


def cli():
    # Initialize parser
    parser = argparse.ArgumentParser()
    
    parser.add_argument(
      "-f",
      "--file",
      default="./tfs-config.yaml",
      type=str,
      help="configuration file with TFS environment flags"
    )
    
    # Kubernetes configuration file path
    parser.add_argument(
        "-k",
        "--kubeconfig",
        default="~/.kube/config",
        type=str,
        help="path to the Kubernetes configuration file",
    )

    parser.add_argument(
        "-m",
        "--manifests",
        default="../manifests/",
        type=str,
        help="path to the manifests directory",
    )
    
    # TFS flags

    parser.add_argument(
        "--registry-images",
        default="http://localhost:32000/tfs/",
        type=str,
        help="the URL of the Docker registry where the images will be uploaded to",
    )

    parser.add_argument(
        "--component",
        default=[
            "context",
            "device",
            "automation",
            "monitoring",
            "pathcomp",
            "service",
            "slice",
            "compute",
            "webui",
            "load_generator",
        ],
        nargs="+",
        type=str,
        help="the list of components, separated by spaces, you want to build images for, and deploy",
    )

    parser.add_argument(
        "--image-tag",
        default="dev",
        type=str,
        help="the tag you want to use for your images",
    )

    parser.add_argument(
        "--k8s-namespace",
        default="tfs",
        type=str,
        help="the name of the Kubernetes namespace to deploy TFS to",
    )

    parser.add_argument(parser.parse_args()
        help="additional manifest files to be applied after the deployment",
    )

    parser.add_argument(
        "--grafana-password",
        default="admin123+",
        type=str,
        help="the new Grafana admin password",
    )

    parser.add_argument(
        "--skip-build",
        action="store_true",
        help="disable skip-build flag to rebuild the Docker images, containers are not rebuilt-retagged-repushed and existing ones are used",
    )

    # CockroachDB flags

    parser.add_argument(
        "--crdb-namespace",
        default="crdb",
        type=str,
        help="the namespace where CockroachDB will be deployed",
    )

    parser.add_argument(
        "--crdb-ext-port-sql",
        default=26257,
        type=int,
        help="the external port CockroachDB Postgre SQL interface will be exposed to",
    )

    parser.add_argument(
        "--crdb-ext-port-http",
        default=8081,
        type=int,
        help="the external port CockroachDB HTTP Mgmt GUI interface will be exposed to",
    )

    parser.add_argument(
        "--crdb-username",
        default="tfs",
        type=str,
        help="the database username to be used by Context",
    )

    parser.add_argument(
        "--crdb-password",
        default="tfs123",
        type=str,
        help="the database user's password to be used by Context",
    )

    parser.add_argument(
        "--crdb-database",
        default="tfs+",
        type=str,
        help="the database name to be used by Context",
    )

    parser.add_argument(
        "--crdb-deploy-mode",
        default="single",
        type=str,
        help="CockroachDB installation mode. Accepted values are: 'single' and 'cluster'",
    )

    parser.add_argument(
        "--crdb-drop-database",
        action="store_true",
        help="the database pointed by variable CRDB_NAMESPACE will be dropped while checking/deploying CockroachDB",
    )

    parser.add_argument(
        "--crdb-redeploy",
        action="store_true",
        help="the database will be dropped while checking/deploying CockroachDB",
    )

    # NATS flags

    parser.add_argument(
        "--nats-namespace",
        default="nats",
        type=str,
        help="the namespace where NATS will be deployed",
    )

    parser.add_argument(
        "--nats-ext-port-client",
        default=4222,
        type=int,
        help="the external port NATS Client interface will be exposed to",
    )

    parser.add_argument(
        "--nats-ext-port-http",
        default=8222,
        type=int,
        help="the external port NATS HTTP Mgmt GUI interface will be exposed to",
    )

    parser.add_argument(
        "--nats-redeploy",
        action="store_true",
        help="the message broker will be dropped while checking/deploying NATS",
    )

    # QuestDB flags

    parser.add_argument(
        "--qdb-namespace",
        default="qdb",
        type=str,
        help="the namespace where QuestDB will be deployed",
    )

    parser.add_argument(
        "--qdb-ext-port-sql",
        default=8812,
        type=int,
        help="the external port QuestDB Postgre SQL interface will be exposed to",
    )

    parser.add_argument(
        "--qdb-ext-port-ilp",
        default=9009,
        type=int,
        help="the external port QuestDB Influx Line Protocol interface will be exposed to",
    )

    parser.add_argument(
        "--qdb-ext-port-http",
        default=9000,
        type=int,
        help="the external port QuestDB HTTP Mgmt GUI interface will be exposed to",
    )

    parser.add_argument(
        "--qdb-username",
        default="admin",
        type=str,
        help="the database username to be used for QuestDB",
    )

    parser.add_argument(
        "--qdb-password",
        default="quest",
        type=str,
        help="the database user's password to be used for QuestDB",
    )

    parser.add_argument(
        "--qdb-table-monitoring",
        default="tfs_monitoring_kpis",
        type=str,
        help="the table name to be used by Monitoring for KPIs",
    )

    parser.add_argument(
        "--qdb-table-slice",
        default="tfs_slice_groups",
        type=str,
        help="the table name to be used by Slice for plotting groups",
    )

    parser.add_argument(
        "--qdb-drop-table",
        action="store_true",
        help="the tables pointed by flags QDB_TABLE_MONITORING_KPIS and QDB_TABLE_SLICE_GROUPS will be dropped while checking/deploying QuestDB",
    )

    parser.add_argument(
        "--qdb-redeploy",
        action="store_true",
        help="the database will be dropped while checking/deploying QuestDB",
    )

    # K8s Observability flags

    parser.add_argument(
        "--prom-ext-port-http",
        default=9090,
        type=int,
        help="he external port Prometheus Mgmt HTTP GUI interface will be exposed to",
    )

    parser.add_argument(
        "--graf-ext-port-http",
        default=3000,
        type=int,
        help="the external port Grafana HTTP Dashboards will be exposed to",
    )
    
    global arguments
    arguments = parser.parse_args()
    
    main()