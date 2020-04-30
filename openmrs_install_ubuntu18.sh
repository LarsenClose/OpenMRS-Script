#!/bin/sh

echo "Please input a password for your mysql root user:"

read varpass

quoted_varpass="'${varpass}'"


echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
sudo apt update
sudo apt install mysql-server -y
sudo mysql_secure_installation &> /dev/null << EOT
y
0
${varpass}
${varpass}
y
y
y
y
EOT

sudo mysql -e "USE mysql;SELECT User, Host, plugin FROM mysql.user;
UPDATE user SET plugin='mysql_native_password' WHERE User='root';
COMMIT;
UPDATE mysql.user SET authentication_string=PASSWORD($quoted_varpass) WHERE User='root';"

sudo systemctl restart mysql

unset varpass
unset quoted_varpass

sudo apt install openjdk-8-jdk -y
sudo apt install git -y
sudo apt install maven -y
sudo apt install curl -y



sudo mkdir /opt/tomcat
sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

curl -o /tmp/tomcat.tar.gz https://downloads.apache.org/tomcat/tomcat-8/v8.5.53/bin/apache-tomcat-8.5.53.tar.gz
sudo tar xzvf /tmp/tomcat.tar.gz -C /opt/tomcat --strip-components=1
cd /opt/tomcat;sudo chgrp -R tomcat /opt/tomcat;sudo chmod -R g+r conf;sudo chmod g+x conf;sudo chown -R tomcat webapps/ work/ temp/ logs/
sudo usermod -aG tomcat $USER

sudo tee -a /etc/systemd/system/tomcat.service > /dev/null <<EOT
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOT

cd;git clone https://github.com/openmrs/openmrs-core.git

cd openmrs-core; mvn clean install -DskipTests


cd webapp; mvn tomcat:run &

firefox http://localhost:8080/openmrs-webapp 



