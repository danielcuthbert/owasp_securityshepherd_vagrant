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
apt-get -y install vim curl build-essential python-software-properties language-pack-en > /dev/null 2>&1

echo -e "\n--- Updating packages list ---\n"
apt-get -qq update

echo -e "\n--- Installing MySQL specific packages and settings ---\n"
echo "mysql-server mysql-server/root_password password $DBPASSWD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DBPASSWD" | debconf-set-selections
apt-get -y install mysql-server > /dev/null 2>&1

echo -e "\n--- Installing Tomcat  ---\n"
apt-get -y install tomcat7 tomcat7-admin tomcat7-common > /dev/null 2>&1
service tomcat7 restart

echo -e "\n--- Pulling down the SQL files, creating databases and importing databases ---\n"
cd /usr/share/mysql/
curl "https://raw.githubusercontent.com/danielcuthbert/owasp_securityshepherd_vagrant/master/coreSchema.sql" -o coreSchema.sql
curl "https://raw.githubusercontent.com/danielcuthbert/owasp_securityshepherd_vagrant/master/moduleSchemas.sql" -o moduleSchemas.sql
mysql -u root --password=CowSaysMoo -e "create database coreSchema"
mysql -u root --password=CowSaysMoo coreSchema < coreSchema.sql
mysql -u root --password=CowSaysMoo -e "create database moduleSchemas"
mysql -u root --password=CowSaysMoo moduleSchemas < moduleSchemas.sql

echo -e "\n--- Pulling down the WAR file and moving into place ---\n"
cd /var/lib/tomcat7/webapps/
rm -R ROOT
curl "https://raw.githubusercontent.com/danielcuthbert/owasp_securityshepherd_vagrant/master/ROOT.war" -o ROOT.war

echo -e "\n--- Installing MongoDB (this may take a while, be patient!)---\n"
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
apt-get -qq update
apt-get install -y mongodb-org mongodb-org-server mongodb-org-shell mongodb-org-mongos mongodb-org-tools

echo -e "\n--- Installing MongoDB Schema ---\n"
export LC_ALL=C
cd /tmp
curl "https://raw.githubusercontent.com/danielcuthbert/owasp_securityshepherd_vagrant/master/mongoSchema.js" -o mongoSchema.js
mongo /tmp/mongoSchema.js




# Set envvars
export APP_ENV=$APPENV
export DB_HOST=$DBHOST
export DB_NAME=$DBNAME
export DB_USER=$DBUSER
export DB_PASS=$DBPASSWD
