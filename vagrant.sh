#!/usr/bin/env bash

sudo apt-get update

# Prepare MySQL installation without password prompt
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

# Install Apache, PHP & MySQL
sudo apt-get install -y php5 apache2 libapache2-mod-php5 php5-curl php5-gd php5-mcrypt mysql-server php5-mysql php5-xdebug

# Configure Xdebug
cat << EOF | sudo tee -a /etc/php5/mods-available/xdebug.ini
xdebug.remote_enable = 1
xdebug.remote_connect_back = 1
xdebug.remote_port = 9000
xdebug.scream = 1
xdebug.cli_color = 1
xdebug.show_local_vars = 1
EOF

# Enable mod_rewrite
sudo a2enmod rewrite

# Configure PHP error reporting
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/apache2/php.ini
sed -i "s/html_errors = .*/html_errors = On/" /etc/php5/apache2/php.ini

sudo service apache2 restart

# Enable remote access to database
sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
MYSQL=`which mysql`
Q1="GRANT ALL ON *.* TO 'root'@'192.168.33.1' IDENTIFIED BY 'root' WITH GRANT OPTION;"
Q2="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}"
$MYSQL -uroot -proot -e "$SQL"

sudo service mysql restart