#!/usr/bin/env bash

sudo add-apt-repository -y ppa:nginx/stable
sudo apt-get update

# Prepare MySQL installation without password prompt
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

# Install Nginx, PHP, MySQL and zip
sudo apt-get install -y nginx mysql-server php5-fpm php5-mysql php5-cli php5-curl php5-gd php5-mcrypt php5-intl php5-xdebug ssl-cert zip

# Configure Nginx
sudo cat << 'EOF' | sudo tee /etc/nginx/nginx.conf
user www-data;
worker_processes 1;
pid /run/nginx.pid;

events {
        worker_connections 768;
        # multi_accept on;
}

http {
        ##
        # Basic Settings
        ##

        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        keepalive_timeout 20;
        types_hash_max_size 2048;
        # server_tokens off;

        # server_names_hash_bucket_size 64;
        # server_name_in_redirect off;

        include /etc/nginx/mime.types;
        default_type application/octet-stream;

        ##
        # SSL Settings
        ##

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
        ssl_prefer_server_ciphers on;

        ##
        # Logging Settings
        ##

        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        ##
        # Gzip Settings
        ##

        gzip on;
        gzip_disable "msie6";

        gzip_vary on;
        gzip_proxied any;
        gzip_comp_level 5;
        gzip_min_length 256;
        # gzip_buffers 16 8k;
        # gzip_http_version 1.1;
        gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

        ##
        # Virtual Host Configs
        ##

        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;
}
EOF
sudo cat << 'EOF' | sudo tee /etc/nginx/sites-enabled/default
server {
        listen 80;
        listen [::]:80;

        listen 443 ssl spdy;
        listen [::]:443 ssl spdy;

        include snippets/snakeoil.conf;

        server_name vagrant.dev;

        root /var/www/vagrant.dev/public;

        index index.php index.html index.htm;

        location / {
                try_files $uri $uri/ /index.php?$query_string;
        }

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/var/run/php5-fpm.sock;
        }

        location ~ /\.ht {
                deny all;
        }
}
EOF

# Enable mcrypt
sudo php5enmod mcrypt

# Configure Xdebug
sudo cat << EOF | sudo tee -a /etc/php5/mods-available/xdebug.ini
xdebug.remote_enable = 1
xdebug.remote_connect_back = 1
xdebug.remote_port = 9000
xdebug.scream = 1
xdebug.cli_color = 1
xdebug.show_local_vars = 1
xdebug.profiler_enable_trigger = 1
xdebug.profiler_output_dir = "/vagrant"
xdebug.profiler_output_name = "cachegrind.out.%s"
xdebug.var_display_max_depth = -1
xdebug.var_display_max_children = -1
xdebug.var_display_max_data = -1
EOF

# Remove default DocumentRoot folder
sudo rm -rf /var/www/html

# Configure PHP
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/fpm/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/fpm/php.ini
sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
sudo sed -i "s/;pm.max_requests = 500/pm.max_requests = 500/" /etc/php5/fpm/pool.d/www.conf

sudo service php5-fpm restart
sudo service nginx restart

# Enable remote access to database
sudo sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
MYSQL=`which mysql`
Q1="GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;"
Q2="FLUSH PRIVILEGES;"
Q3="CREATE DATABASE \`vagrant_dev\` COLLATE utf8_unicode_ci;"
SQL="${Q1}${Q2}${Q3}"
$MYSQL -uroot -proot -e "$SQL"

sudo service mysql restart
