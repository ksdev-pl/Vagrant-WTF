#!/usr/bin/env bash

sudo add-apt-repository -y ppa:nginx/stable
sudo apt-get update

# Prepare MySQL installation without password prompt
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

# Install Nginx, PHP, MySQL and zip
sudo apt-get install -y nginx mysql-server php5-fpm php5-mysql php5-cli php5-curl php5-gd php5-mcrypt php5-intl php5-xdebug zip

# Configure Nginx
sudo sed -i "s/worker_processes 4/worker_processes 1/" /etc/nginx/nginx.conf
sudo cat << 'EOF' | sudo tee /etc/nginx/sites-enabled/default
server {
        listen 80 default_server;
        listen [::]:80 default_server;

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
