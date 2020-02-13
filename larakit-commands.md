# Larakit Commands

## Laradock commands

-	Install Laradock

		larakit laradock install

-	Pull latest Laradock update

    	larakit laradock pull

-	Copy custom config files to Laradock

    	larakit laradock config
    	
-	Switch active PHP version

		larakit switch 7.4


## Docker (Laradock) stack commands

-	Launch service stack

		larakit up [service...]

-	Shutdown service stack

		larakit down

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


-	Start a bash shell in the project

		larakit exec|run bash


-	Run PHPUnit
	
		larakit exec|run ./vendor/bin/phpunit


-	Run NPM

		larakit exec|run npm ...
		


