# variables: $domain

echo 'Performing spring boot app configuration...'
# copy the application.properties file to the default location when the site is
# built
sed -i -e '/application.properties/ { s/^# //g; }' /srv/${domain}/cods-config
# create a default application.properties file
echo '# put your configuration here' > /srv/${domain}/application.properties
