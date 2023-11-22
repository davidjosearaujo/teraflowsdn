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
    }:
}' > /home/vagrant/expose-linkerd

# Create symlink of the NGINX configuration file
sudo ln -s /home/vagrant/expose-linkerd /etc/nginx/sites-enabled/

# Commit the reverse proxy configurations
sudo systemctl restart nginx

echo '[Unit]
Description=Linkerd Viz dashboard
After=network.target
StartLimitIntervalSec=0
[Service]
Type=simple
Restart=always
RestartSec=1
User=vagrant
ExecStart=linkerd viz dashboard

[Install]
WantedBy=multi-user.target' > linkerdviz.service

sudo cp ./linkerdviz.service /etc/systemd/system/linkerdviz.service

# Start Linkerd Viz dashboard
sudo systemctl start linkerdviz

# Enable start on boot
sudo systemctl enable linkerdviz

echo "Linkerd Viz dashboard running!"
