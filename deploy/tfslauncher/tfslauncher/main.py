import yaml
import argparse
from pathlib import Path
import kubernetes
from kubernetes import client, config, utils



#def _crdb():
    # Create namespace
    
def main():
    # Load variables from yaml
    if 'file' in arguments:
        default_config = yaml.safe_load(Path(arguments['file']).read_text())
    else:
        default_config = {
            'tfs': {
                'registry-images': 'http://localhost:32000/tfs/',
                'component': [
                    'context',
                    'device',
                    'automation',
                    'monitoring',
                    'pathcomp',
                    'service',
                    'slice',
                    'compute',
                    'webui',
                    'load_generator'
                ],
                'image-tag': 'dev1',
                'k8s-namespace': 'tfs',
                'grafana-password': 'admin123+'
            }, 
            'crdb': {
                'namespace': 'crdb',
                'external-ports': {
                    'sql': 26257,
                    'http': 8081}, 
                'credentials': {
                    'username': 'tfs',
                    'password': 'tfs123'
                },
                'database': 'tfs',
                'deploy-mode': 'single'
            },
            'nats': {
                'namespace': 'nats',
                'external-ports': {
                    'client': 4222,
                    'http': 8222
                }
            },
            'qdb': {
                'namespace': 'qdb',
                'external-ports': {
                    'sql': 8812,
                    'ilp': 9009,
                    'http': 9000
                },
                'credentials': {
                    'username': 'admin',
                    'password': 'quest'
                },
                'tables': {
                    'monitoring-kpis': 'tfs_monitoring_kpis',
                    'slice-groups': 'tfs_slice_groups'
                }
            },
            'service-ports': {
                'prometheus-http': 9090,
                'grafana-http': 3000
            }
        }
    
    config.load_kube_config()
    api_client = client.ApiClient()
    api_instance = kubernetes.client.CoreV1Api(api_client)
    api_response = api_instance.create_namespace(kubernetes.client.V1Namespace())
    print(api_response)
    # TODO create namespace from variables
    
    
    # TODO Load yamls
    # TODO Edit yamls with variables
    # TODO Apply resources.


def cli():
    # Default configurations
    global default_config
    
    # Initialize parser
    parser = argparse.ArgumentParser()
    
    parser.add_argument(
      "-f",
      "--file",
      default=argparse.SUPPRESS,
      type=str,
      help="configuration file with TFS environment flags",
    )
    
    global arguments
    arguments = parser.parse_args()
    arguments = dict(arguments._get_kwargs())
    
    main()