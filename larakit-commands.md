# Larakit Commands

## Laradock commands

-	Install Laradock

		larakit laradock install

-	Pull latest Laradock update

    	larakit laradock pull

-	Copy custom config files to Laradock

    	larakit laradock config


## Docker (Laradock) stack commands

-	Launch service stack

		larakit up -d [service, ...]

-	Shutdown service stack

		larakit down

-	List running services

		larakit ps

-	Show service logs

		larakit logs
		

## Project Creation Commands

-	Create a new Laravel  PHP 7 project

    	larakit composer create-project --prefer-dist laravel/laravel projectdir


## Project Commands : run from top level project directory

-	Update dependencies for a project

		larakit composer update


-	Start a bash shell in the project

		larakit bash


-	Run PHPUnit
	
		larakit ./vendor/bin/phpunit


-	Run NPM

		larakit npm ...
		


