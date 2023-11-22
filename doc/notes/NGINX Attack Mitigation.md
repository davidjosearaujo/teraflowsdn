- [Mitigating DDoS Attacks with NGINX and NGINX Plus](https://www.nginx.com/blog/mitigating-ddos-attacks-with-nginx-and-nginx-plus/)
- [How to Protect from DDoS Attacks with Nginx](https://gcore.com/learning/nginx-for-ddos-protection/)
## Ingress configuration
### View configurations
```
$ kubectl get pods -n ingress
$ kubectl exec -it -n ingress nginx-ingress-microk8s-controller-<value> -- cat /etc/nginx/nginx.conf
```
Configure the ingress controller to limit the connections request limit, number of concurrent connections to the same IP address, among other specifications, using [Annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#external-authentication)

To update ingress rules, it is as simple as **editing the original manifest and reapplying it**.
```
$ kubectl apply -f <manifest-file>
```

Options used:
- nginx.ingress.kubernetes.io/auth-keepalive
- nginx.ingress.kubernetes.io/auth-keepalive-timeout
- nginx.ingress.kubernetes.io/limit-rps
- nginx.ingress.kubernetes.io/limit-connections
- nginx.ingress.kubernetes.io/proxy-connect-timeout
- nginx.ingress.kubernetes.io/proxy-send-timeout
- nginx.ingress.kubernetes.io/proxy-read-timeout
## Programmatic solutions

Develop a traffic monitoring service that is able to update NGINX configurations, namely:
- Blacklisting IP address.
- Route blocking.
- Traffic redirection.
- ...