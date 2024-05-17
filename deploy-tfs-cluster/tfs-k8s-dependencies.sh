microk8s.enable community

microk8s.enable dns helm3 hostpath-storage ingress registry prometheus metrics-server linkerd

sudo snap alias microk8s.helm3 helm3
sudo snap alias microk8s.linkerd linkerd

linkerd check

kubectl top pods --all-namespaces