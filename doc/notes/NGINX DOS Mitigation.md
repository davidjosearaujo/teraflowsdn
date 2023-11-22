- [Mitigating DDoS Attacks with NGINX and NGINX Plus](https://www.nginx.com/blog/mitigating-ddos-attacks-with-nginx-and-nginx-plus/)
- [How to Protect from DDoS Attacks with Nginx](https://gcore.com/learning/nginx-for-ddos-protection/)

- [ ] Limiting:
	- [ ] Rate of request
	- [ ] Number of connection
- [ ] Closing slow connections

Programmatic solutions:
- [ ] Real-time traffic analyzer and NGINX configuration blacklists update 
## Ingress configuration
Configure the ingress controller to limit the connections request limit, number of concurrent connections to the same IP address, among other specifications, using [Annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#external-authentication)

Options used:
- 
