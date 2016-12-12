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
    default-jdk

header "Installing tomcat."

# download the tar from apache and extract it to /opt/tomcat
mkdir -p /opt/tomcat
cd /tmp
wget http://mirrors.ocf.berkeley.edu/apache/tomcat/tomcat-8/v8.5.9/bin/apache-tomcat-8.5.9.tar.gz
tar xzvf apache-tomcat-8.5.9.tar.gz --strip-components=1 -C /opt/tomcat
rm apache-tomcat-8.5.9.tar.gz

# create a tomcat user
sudo groupadd tomcat
sudo useradd -g tomcat -s /bin/false -d /opt/tomcat tomcat

# set permissions for the tomcat install
chown -R tomcat /opt/tomcat

# disable password login + root login
perl -i -pe 's/(PasswordAuthentication\s*)yes/\1no/' /etc/ssh/sshd_config
perl -i -pe 's/(PermitRootLogin\s*)yes/\1no/' /etc/ssh/sshd_config
service sshd restart
service ssh restart
