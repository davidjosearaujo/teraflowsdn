# Install NGINX
sudo apt install nginx -y

# Create symlink of the NGINX configuration file
sudo ln -s $HOST/tfs-ctrl/expose-linkerd/expose-linkerd.conf /etc/nginx/sites-enabled/

# Commit the reverse proxy configurations
sudo systemctl restart nginx

# Initiate linkerd dashboard
linkerd viz dashboard &