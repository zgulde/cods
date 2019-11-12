wait_to_continue() {
	echo
	read -p 'Press enter to continue or Ctrl-C to exit'
	clear
}

initial_server_setup() {
	cat <<-.
	[0/2] Initial Server Setup | Prerequisites
	------------------------------------------

	Let's create A VPS and a command to interact with it

	Prerequisites

	- An account with a VPS provider (e.g. Digital Ocean)
	- cods installed (this should already be taken care of if you are seeing
	  this message)
	.
	wait_to_continue

	cat <<-.
	[1/2] Initial Server Setup | Droplet Creation
	---------------------------------------------

	Create a Server (Digital Ocean calls these "droplets") with the following
	specifications:

	- Debian 10 Buster (debian-10 x64)
	- At least 1GB of Memory (RAM)

	If you have already created a droplet in the past, you can skip the step
	below, but be sure to check the checkbox for your existing ssh key.

	Add your public ssh key to the server. This command will copy the contents
	of your public key to your clipboard so that you can paste it:

	    cat ~/.ssh/id_rsa.pub | pbcopy

	(If you are on Linux, you'll probably need to do something a bit different
	here, but we trust your ability to do so)
	.
	wait_to_continue

	cat <<-.
	[2/2] Initial Server Setup | Command Creation
	---------------------------------------------

	Now we'll setup the command to interact with your server. You'll now need to
	choose a command name. The command name you choose will be the name of the
	command that is created to interact with your server.

	You might wish to choose something like 'myserver', or 'blog-server'.

	.
	read -p 'What would you like to name your server? ' command_name
	cat <<-.

	Okay! Make sure you have access to your server's ip address, then run:

	    cods init $command_name

	To provision the server and setup the command.

	After answering the prompts, it's a good time to grab a refreshing beverage
	as the setup/provisioning process takes a few minutes.
	.
}

sb_application_prep() {
	cat <<-.
	[0/6] Spring Boot Application Prep
	----------------------------------

	Let's get your spring boot application ready for deployment!

	We'll walk through the changes you'll need to make to your application in
	order to deploy your project.
	.
	wait_to_continue

	cat <<-.
	[1/6] Spring Boot Application Prep | Make Sure We're In The Right Place
	-----------------------------------------------------------------------

	First, navigate to your project's directory, for example

	    cd ~/IdeaProjects/my-project

	Make sure you are on the master branch, and have a clean working directory
	(all changes have been committed.)
	.
	wait_to_continue

	cat <<-.
	[2/6] Spring Boot Application Prep | Create a Jar File
	------------------------------------------------------

	First we'll make sure that your application is able to be packaged as a jar
	successfully. Go ahead and run this command:

	    ./mvnw package

	Which will produce a .jar file inside the "target" directory.

	If the command fails, inspect the output and fix the errors before
	continuing, then try and package it again.

	Now run

	    ls target/*.jar

	Which will output something like "your-project-0.0.1-SNAPSHOT.jar". Make a
	note of the name of your jar file, as we will reference it several times
	throughout this process.
	.
	wait_to_continue

	cat <<-.
	[3/6] Spring Boot Application Prep | Run The Produced Jar File
	--------------------------------------------------------------

	Next we'll run the jar that was produced.

		java -jar target/YOUR_JAR_FILE

	Replacing "YOUR_JAR_FILE" with the actual name of the file that was
	produced.

	This will start up your application locally just as if you were running the
	main method from your IDE.

	Once this starts up, you should open your browser and make sure everything
	works the way you want it to.

	When you are finished, you can press Ctrl-C to exit the server.
	.
	wait_to_continue

	cat <<-.
	[4/6] Spring Boot Application Prep | Create The .cods File
	----------------------------------------------------------

	Next we'll setup the .cods file. This file will be used to build our project
	on the server.

	Create a plain text file named '.cods' in the root of your project. Copy the
	two lines below into it:

	BUILD_COMMAND='./mvnw package'
	JAR_FILE=

	Now run this command in your terminal:

	    find target -name \*.jar

	it should output the path to the built jar file, something like
	'target/my-project.jar'. Copy the output and paste into the .cods file after
	'JAR_FILE=' *without any spaces*.

	Your .cods file should end up looking something like this:

	BUILD_COMMAND='./mvnw package'
	JAR_FILE=target/blog-0.0.1-SNAPSHOT.jar
	.
	wait_to_continue

	cat <<-.
	[5/6] Spring Boot Application Prep | Validate .cods File
	--------------------------------------------------------

	Now let's verify that the .cods file was setup properly.

	First, run this command:

	    source .cods

	You should see no output.

	Next run this:

	    eval "\$BUILD_COMMAND"

	And your project should build successfully.

	Now run this:

	    [[ -f \$JAR_FILE ]] && echo 'Good to Go!' || echo 'JAR_FILE not found!'

	And you should see "Good to Go!" output. If not, double check the JAR_FILE
	value from the previous step and try again.
	.
	wait_to_continue

	cat <<-.
	[6/6] Spring Boot Application Prep | Add and Commit Changes To master
	---------------------------------------------------------------------

	Lastly, make sure to add and commit all the changes you've made.

	You should make sure the .cods file and the changes you've made to
	yor application are committed *on your master branch*. (This is the branch
	that will be used for deployment)
	.
	wait_to_continue

	echo 'All done! Your application should now be ready to deploy!'

}

sb_site_setup() {
	local server site
	cat <<-.
	[0/8] Spring Boot Site Setup | Prerequisites
	--------------------------------------------

	Let's walk through the process of setting up a site on your server.

	Prerequisites:

	- A domain name
	- A server provisioned with the cods tool
	- DNS records setup to point the domain name to your server
	- An application prepped to be deployed
	.
	wait_to_continue

	cat <<-.
	[1/8] Spring Boot Site Setup | Server Command and Site Name
	-----------------------------------------------------------

	First a couple questions

	In order to better help, we will need the name of the command you use to
	interact with your server, for example, 'myserver'. You created this command
	when you ran 'cods init'

	.
	PS3='Please enter a number: '
	select server in $(find "$BASE_DATA_DIR" -type d -depth 1 | perl -pe 's!^.*/(.*)$!\1!g') ; do
		break
	done

	cat <<-.

	Next we'll need the name of the site you are setting up. You should enter
	just the domain name, i.e. don't enter www. or http://, just a value like
	'example.com'

	.
	read -p 'Site name: ' site

	cat <<-.

	Thanks! Please take a second to double check that this information is
	correct:

	server command: $server
	site name: $site
	.
	wait_to_continue

	cat <<-.
	[2/8] Spring Boot Site Setup | Database Creation
	------------------------------------------------

	Let's make a database for your application (you can skip this step if your
	application doesn't use a database).

	We'll ask for the name of the database you want to setup, as well as the
	name of the database user to be created (the created user will only have
	permissions on the database that is being created).

	.

	read -p 'database name (e.g. blog_db): ' db_name
	read -p 'database user (e.g. blog_user): ' db_user

	cat <<-.

	Double check that the database name and user are spelled the way you want
	them to be, then go ahead and run

	    $server db create --name $db_name --user $db_user

	You'll be prompted for your database admin password that was generated when
	the server was setup. You can find this by running:

	    $server credentials

	either in a new terminal, or before you run the db command above.
	.
	wait_to_continue

	cat <<-.
	[3/8] Spring Boot Site Setup | Find a Port For Your Application
	---------------------------------------------------------------

	Now let's find a free port for your application. Run this command to view
	the ports that are in use on your server:

	    $server ports

	(You might not see anything if you don't have any sites setup yet). Choose a
	port number for your application. Anything between 1024 and 65535 is valid,
	but it is common to choose a number such as 8080, 8000, 8888, 3000, or 5000

	.

	read -p 'What port number will you use? ' port

	cat <<-.

	Got it, we'll host the site on port $port.
	.
	wait_to_continue

	cat <<-.
	[4/8] Spring Boot Site Setup | Create The Site
	----------------------------------------------

	Next we will tell your server that it is going to host $site

	Go ahead and run this command:

	    $server site create --domain $site --java --spring-boot --port $port

	You should see some output that explains what is being setup, ending with
	"- Finished Setting Up $site"
	.
	wait_to_continue

	cat <<-.
	[5/8] Spring Boot Site Setup | Upload The application.properties File
	---------------------------------------------------------------------

	We will now need to setup the production application.properties file. An
	easy way to do this is to start by transferring your local
	application.properties to the server, then modifying it there.

	Navigate to your project directory (if you aren't there already):

	    cd ~/IdeaProjects/my-project-to-deploy

	Replacing "my-project-to-deploy" with the directory your project is in

	And run this command to transfer your application.properties file to the
	server:

	    $server upload --file src/main/resources/application.properties --destination /srv/$site/

	(The command above is a little long, if your terminal splits it into
	multiple lines, make sure to copy the entire command (or make your terminal
	window bigger))
	.
	wait_to_continue

	cat <<-.
	[6/8] Spring Boot Site Setup | Edit The application.properties File on the Server
	---------------------------------------------------------------------------------

	Now we'll edit the application.properties file on the server

	    $server run nano /srv/$site/application.properties

	This will open up the command line editor nano on your server. You'll need
	to use the arrow keys to navigate here, as nano does not recognize your
	mouse clicks.

	In this file, make sure that the database name and database user match the
	values you setup earlier,

	    db name: $db_name
	    db user: $db_user

	And make sure the password matches the autogenerated password that was
	created. You can find this password by running:

	    myserver credentials

	To save and exit nano:

	1. Ctrl-X
	2. Type 'y'
	3. Press Enter
	.
	wait_to_continue

	cat <<-.
	[7/8] Spring Boot Site Setup | Add and Push To The production Remote
	--------------------------------------------------------------------

	Lastly, we'll add the deployment remote to our project and push.

	Run this command:

	    $server site info --domain $site

	To view information about your site, including your git deployment
	remote. Copy and paste the displayed command to add the 'production' remote,
	then push to production:

	    git push production master

	After you push, the server will build your project and deploy it. Inspect
	the output of pushing, it will contain all the information about building
	your project, any errors that happen in the build phase will be shown here.

	You may have to wait ~60 seconds after the push finishes for your
	application to start up, then you should be able to visit the site in your
	browser.
	.
	wait_to_continue

	cat <<-.
	[8/8] Spring Boot Site Setup | Troubleshooting: Log files
	---------------------------------------------------------

	One of the first places to look when you are troubleshooting a site that is
	not working is the log files.

	There are two ways to view the log files on your server, the simplest is:

	    $server site logs --domain $site

	You can also watch the logs for your site on your server in real time, run

	    $server site logs --domain $site --follow

	Press Ctrl-C to stop watching the logs.

	The above command is useful when run immediately after pushing, as you can
	watch your application as it starts up.
	.
	wait_to_continue

	echo 'All done!'
}

static_site_setup() {
	local server site
	cat <<-.
	[0/?] Static Site Setup | Prerequisites
	---------------------------------------

	Let's walk through the process of setting up a site on your server.

	Prerequisites:

	- A domain name
	- A server provisioned with the cods tool
	- DNS records setup to point the domain name to your server
	- An application prepped to be deployed
	.
	wait_to_continue

	cat <<-.
	[1/?] Static Site Setup | Server and Domain Name
	------------------------------------------------

	First a couple questions

	In order to better help, we will need the name of the command you use to
	interact with your server, for example, 'myserver'. You created this command
	when you ran 'cods init'

	.
	PS3='Please enter a number: '
	select server in $(find "$BASE_DATA_DIR" -type d -depth 1 | perl -pe 's!^.*/(.*)$!\1!g') ; do
		break
	done

	cat <<-.

	Next we'll need the name of the site you are setting up. You should enter
	just the domain name, i.e. don't enter www. or http://, just a value like
	'example.com'

	.
	read -p 'Site name: ' site

	cat <<-.

	Thanks! Please take a second to double check that this information is
	correct:

	server command: $server
	site name: $site
	.
	wait_to_continue

	cat <<-.
	[2/?] Static Site Setup | Create The Site
	-----------------------------------------

	Allright, let's create the site on the server

	Run this command:

	    $server site create --domain $site --static

	You'll be prompted for your sudo password, the server admin password. You
	can also find this by running:

	    $server credentials

	In a separate terminal, or running it before you run the site create
	command.
	.
	wait_to_continue

	cat <<-.
	[3/?] Static Site Setup | Build Step
	------------------------------------

	If your site has a build step (i.e. if you are using webpack, or run something
	like "npm run build") we can guide you through some additional configuration
	for your project.

	.
	if confirm 'Does your site have a build step?' ; then
		echo 'TODO: Write these docs'
	else
		echo "Okay, let's carry on then."
	fi

	wait_to_continue

	cat <<-.
	[4/?] Static Site Setup | Add and Push To The production Remote
	---------------------------------------------------------------

	Lastly, we'll add the deployment remote to our project and push.

	Run this command:

	    $server site info --domain $site

	To view information about your site, including your git deployment
	remote. Copy and paste the displayed command to add the 'production' remote,
	then push to production:

	    git push production master

	If your project has a build step, it will start now, and after it finishes,
	the output will be available at http://$site

	Otherwise the current version of your repository will be available at
	http://$site
	.
	wait_to_continue

	echo "Have a great rest of your $(date +%A)!"
}

# TODO: node sites, static sites, DNS Records, troubleshooting?

cat <<-.
Welcome to the interactive deployment guide!

This is a rough translation of the documentation included in this repo to an
interactive cli format.

This will ask you some questions, and provide you with information and, in some
cases, copy and pastable commands. It is recommended that you have this help
open in one terminal, and a separate terminal open to run commands in.

This help will *not* run any commands for you, it will only display information
and commands that you can use. This means it is totally fine to exit and run
this script over and over again.

You can exit at any time by pressing Ctrl-C

What do you need help with?

.


topics=(
	'initial server setup'
	'spring boot application prep'
	'spring boot application site setup'
	# 'static site deployment'
	'exit'
)

PS3='Please enter a number: '
select _ in "${topics[@]}" ; do
	clear
	case $REPLY in
		1) initial_server_setup;;
		2) sb_application_prep;;
		3) sb_site_setup;;
		4) exit;;
		# 4) static_site_setup;;
		# 5) exit;;
		*) echo "Invalid Selection, $REPLY";;
	esac
	break
done
