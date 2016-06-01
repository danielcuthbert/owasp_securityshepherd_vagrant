#! /usr/bin/env bash
# This will install the necessary dependencies required to run the OWASP Security Shepherd
# https://www.owasp.org/index.php/OWASP_Security_Shepherd
# Daniel Cuthbert


# Variables
APPENV=local
DBHOST=localhost
DBNAME=dbname
DBUSER=dbuser
DBPASSWD=CowSaysMoo

echo -e "\n--- Let's get OWASP Security Shepherd Installed... ---\n"

echo -e "\n--- Updating packages list ---\n"
apt-get -qq update

echo -e "\n--- Install base packages ---\n"
apt-get -y install vim curl build-essential python-software-properties git > /dev/null 2>&1

echo -e "\n--- Updating packages list ---\n"
apt-get -qq update

echo -e "\n--- Installing MySQL specific packages and settings ---\n"
echo "mysql-server mysql-server/root_password password $DBPASSWD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections
apt-get -y install mysql-server > /dev/null 2>&1

echo -e "\n--- Setting up our MySQL user and db ---\n"
mysql -uroot -p$DBPASSWD -e "CREATE DATABASE $DBNAME"
mysql -uroot -p$DBPASSWD -e "grant all privileges on $DBNAME.* to '$DBUSER'@'localhost' identified by '$DBPASSWD'"

echo -e "\n--- Installing Apache2  ---\n"
apt-get -y install apache2 > /dev/null 2>&1

echo -e "\n--- Setting document root to public directory ---\n"
rm -rf /var/www
ln -fs /vagrant/public /var/www


echo -e "\n--- Add environment variables to Apache ---\n"
cat > /etc/apache2/sites-enabled/000-default.conf <<EOF
<VirtualHost *:80>
    DocumentRoot /var/www
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    SetEnv APP_ENV $APPENV
    SetEnv DB_HOST $DBHOST
    SetEnv DB_NAME $DBNAME
    SetEnv DB_USER $DBUSER
    SetEnv DB_PASS $DBPASSWD
</VirtualHost>
EOF

echo -e "\n--- Restarting Apache ---\n"
service apache2 restart > /dev/null 2>&1

echo -e "\n--- Installing Tomcat  ---\n"
apt-get -y install tomcat7 tomcat7-admin tomcat7-common > /dev/null 2>&1

echo -e "\n--- Pulling down the SQL files, creating databases and importing databases ---\n"
cd /usr/share/mysql/
curl "https://raw.github.com/danielcuthbert/owasp_securityshepherd_vagrant/blob/master/coreSchema.sql" -o coreSchema.sql
curl "https://raw.github.com/danielcuthbert/owasp_securityshepherd_vagrant/blob/master/moduleSchemas.sql" -o moduleSchemas.sql
mysql -u root --password=CowSaysMoo -e "create database coreSchema"
mysql -u root --password=CowSaysMoo coreSchema < coreSchema.sql
mysql -u root --password=CowSaysMoo -e "create database moduleSchemas"
mysql -u root --password=CowSaysMoo moduleSchemas < moduleSchemas.sql


echo -e "\n--- Pulling down the WAR file and moving into place ---\n"
cd /var/lib/tomcat7/webapps/
rm -R ROOT
curl "https://raw.githubusercontent.com/danielcuthbert/owasp_securityshepherd_vagrant/master/ROOT.war" -o ROOT.war /dev/null 2>&1
service tomcat7 restart

# Set envvars
export APP_ENV=$APPENV
export DB_HOST=$DBHOST
export DB_NAME=$DBNAME
export DB_USER=$DBUSER
export DB_PASS=$DBPASSWD
