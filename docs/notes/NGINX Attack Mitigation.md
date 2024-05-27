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
$ kubectl --namespace tfs apply -f <manifest-yaml>
```

Options used:
- [nginx.ingress.kubernetes.io/limit-rps](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#rate-limiting)
- [nginx.ingress.kubernetes.io/limit-connections](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#rate-limiting)
- [nginx.ingress.kubernetes.io/proxy-connect-timeout](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#custom-timeouts)
- [nginx.ingress.kubernetes.io/proxy-send-timeout](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#custom-timeouts)
- [nginx.ingress.kubernetes.io/proxy-read-timeout](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#custom-timeouts)

## Testing
Create a LAN with two clients and a server. One of the clients is the attacker, the other is a legitimate user. The attacker will continue to spam the server and the legitimate user should maintain access to the controller, however, it may experience DOS at the very beginning of the attack.
## Programmatic solutions

Develop a traffic monitoring service that is able to update NGINX configurations, namely:
- Blacklisting IP address.
- Route blocking.
- Traffic redirection.
- ...