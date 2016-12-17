heading(){
    echo '----------------------------------'
    echo "> $@"
    echo '----------------------------------'
}

heading 'updating + upgrading apt'

apt-get update
yes | apt-get upgrade

heading 'installing nginx, java'

apt-get install -y\
    nginx\
    default-jdk\
    ufw\
    mysql-server

# https://serversforhackers.com/video/installing-mysql-with-debconf

heading "Installing tomcat."

# download the tar from apache and extract it to /opt/tomcat
mkdir -p /opt/tomcat
cd /tmp
wget http://mirrors.ocf.berkeley.edu/apache/tomcat/tomcat-8/v8.5.9/bin/apache-tomcat-8.5.9.tar.gz
tar xzvf apache-tomcat-8.5.9.tar.gz --strip-components=1 -C /opt/tomcat
rm apache-tomcat-8.5.9.tar.gz

# create a tomcat user
groupadd tomcat
useradd -g tomcat -s /bin/false -d /opt/tomcat tomcat

# set permissions for the tomcat install
chown -R tomcat /opt/tomcat
chmod a+w /opt/tomcat/webapps

## Here we should create the tomcat service and start it
nohup /opt/tomcat/bin/startup.sh &

## find the java installation path
java_home=$(update-java-alternatives | awk '{print $3}')/jre

# create the tomcat service
cat > /etc/systemd/system/tomcat.service <<tomcat.service 
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=${java_home}
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
tomcat.service

systemctl daemon-reload

# start tomcat now, and have it start automatically on boot
systemctl enable tomcat
systemctl start tomcat
