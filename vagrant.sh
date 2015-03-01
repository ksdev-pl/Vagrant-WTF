#!/usr/bin/env bash

sudo apt-get update

# Prepare MySQL installation without password prompt
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

# Install Apache, PHP & MySQL
sudo apt-get install -y php5 apache2 libapache2-mod-php5 php5-curl php5-gd php5-mcrypt mysql-server php5-mysql php5-xdebug zip

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

# Configure Apache
sudo a2enmod ssl
sudo a2ensite default-ssl.conf
sudo a2enmod rewrite headers
sudo sed -i '165 s/Options Indexes FollowSymLinks/Options FollowSymLinks/' /etc/apache2/apache2.conf
sudo sed -i '166 s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
sudo sed -i '12 s/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/public/' /etc/apache2/sites-enabled/000-default.conf
sudo sed -i '5 s/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/public/' /etc/apache2/sites-enabled/default-ssl.conf

# Remove default DocumentRoot folder
sudo rm -rf /var/www/html

# Configure PHP
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/apache2/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/apache2/php.ini
sudo sed -i "s/html_errors = .*/html_errors = On/" /etc/php5/apache2/php.ini

sudo service apache2 restart

# Enable remote access to database
sudo sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
MYSQL=`which mysql`
Q1="GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;"
Q2="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}"
$MYSQL -uroot -proot -e "$SQL"

sudo service mysql restart
