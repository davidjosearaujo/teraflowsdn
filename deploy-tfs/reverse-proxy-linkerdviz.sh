# Install NGINX
sudo apt update && sudo apt install nginx -y

echo 'server {
    listen 8084;

    location / {
        proxy_pass http://127.0.0.1:50750;
        proxy_set_header Host localhost;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}' > /home/vagrant/expose-linkerd

# Create symlink of the NGINX configuration file
sudo ln -s /home/vagrant/expose-linkerd /etc/nginx/sites-enabled/

# Commit the reverse proxy configurations
sudo systemctl restart nginx

echo "Linkerd Viz reverse proxy running!"