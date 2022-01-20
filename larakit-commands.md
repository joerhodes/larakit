# Larakit Commands

## Laradock commands

-	Install Laradock

		larakit laradock install

-	Pull latest Laradock update

    	larakit laradock update

-	Copy custom config files to Laradock

    	larakit laradock config
    	
-	Switch active PHP version

		larakit switch 7.4


## Docker (Laradock) stack commands

-	Launch service stack

		larakit up [service...]

-	Shutdown service stack

		larakit down
		
-	Restart service stack

		larakit restart

-	List running services

		larakit ps

-	Show service logs

		larakit logs
		

## Project Creation Commands

-	Create a new Laravel  PHP project

    	larakit exec|run composer create-project --prefer-dist laravel/laravel projectdir


## Project Commands : run from top level project directory

-	Update dependencies for a project

		larakit exec|run composer update


-	Start a bash shell in the project in Docker, so you can avoid typing `larakit exec|run` every time

		larakit exec|run bash


-	Run PHPUnit
	
		larakit exec|run ./vendor/bin/phpunit


-	Run NPM

		larakit exec|run npm ...

		
## Register hostname aliases for NGINX

To allow apps to talk to each other inside of the docker containers, the application hostnames need to mapped to the NGINX container.  This is done by assigning network aliases to the NGINX container.  The following commands all these aliases to be managed.

-	Add an alias
	
		larakit register api.test

-	Remove an alias
	
		larakit deregister api.test

-	Add an alias for the current project
	
		cd ~/Sites/ddgorder
		larakit register

-	Remove an alias for the current project
	
		cd ~/Sites/ddgorder
		larakit deregister

-	Add aliases for all projects

		larakit register all
		
-	Remove aliases for all projects

		larakit deregister all

The larakit stack will need to be restarted after this commands for the aliases to take effect.

	larakit down
	larakit up

## Docker build environment

The file `configs/environment` contains values that are passed to the docker image building process.  Most of the values in this file have been set to satisfy the OS dependencies of various projects.  It may be necessary to disable able one or more of these features when build a new image.  Or it may be necessary to enable a feature that had previously been disabled.  

This file also contains the list of services (containers) that are launched with `larakit up`.   A newly created file contains the bare minimum.   It may be necessary to add more though.  One example is adding **beanstalkd** and **beanstalkd-console** to the list of `DEFAULT_SERVICES`.  Note that these service names are defined in the `laradock/docker-compose.yml` file.

