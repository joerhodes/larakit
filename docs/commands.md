# Larakit Commands

## Laradock Commands

-	Install Laradock

		larakit laradock install

-	Pull the latest Laradock update

    	larakit laradock update

-	Copy custom config files to Laradock

    	larakit laradock config

-	Switch the active PHP version

		larakit switch 8.2


## Docker (Laradock) Stack Commands

-	Launch the service stack

		larakit up [service...]

-	Shut down the service stack

		larakit down

-	Restart the service stack

		larakit restart

-	List running services

		larakit ps

-	Show service logs

		larakit logs


## Project Creation Commands

-	Create a new Laravel PHP project

    	larakit exec|run composer create-project --prefer-dist laravel/laravel projectdir


## Project Commands: run from the top-level project directory

-	Update a project's dependencies

		larakit exec|run composer update

-	Start a bash shell inside the project's container, so you can avoid typing `larakit exec|run` every time

		larakit exec|run bash

-	Run PHPUnit

		larakit exec|run ./vendor/bin/phpunit

-	Run NPM

		larakit exec|run npm ...


## Registering Hostname Aliases for NGINX

To allow apps to talk to each other inside the Docker containers, application hostnames need to be mapped to the NGINX container. This is done by assigning network aliases to the NGINX container. The following commands manage those aliases.

-	Add an alias

		larakit register api.test

-	Remove an alias

		larakit deregister api.test

-	Add an alias for the current project — reads `APP_URL` from `.env`

		cd ~/Sites/project
		larakit register

-	Remove an alias for the current project

		cd ~/Sites/project
		larakit deregister

The larakit stack needs to be restarted for alias changes to take effect:

	larakit down
	larakit up

## Docker Build Environment

The file `configs/environment` contains values passed to the Docker image build process. Most of these values are set to satisfy the OS dependencies of various projects. It may be necessary to disable one or more of these features when building a new image, or to enable a feature that was previously disabled.

This file also contains the list of services (containers) launched by `larakit up`. A newly created file contains the bare minimum — it may be necessary to add more. One example is adding **sftpserver** to `DEFAULT_SERVICES`. Note that these service names are defined in the `laradock/docker-compose.yml` file.

## DNS and VPN

Docker Desktop for Mac can have trouble resolving DNS when a VPN connection's status changes. To help identify whether this is currently an issue, larakit provides a subcommand to test DNS resolution from inside a container:

    larakit dnsCheck

If this fails, return to the [dnsmasq / DNS setup guide](dnsmasq-setup.md) and follow the instructions related to setting up `dnsmasq`.
