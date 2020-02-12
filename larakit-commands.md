# Larakit Commands

## Docker Stack Commands

-	Start the stack

		larakit up

-	Shut down the stack    

    	larakit down

-	Show service status

    	larakit ps

-	Retreive logs

		larakit logs

## Project Creation Commands

-	Create a new Laravel  PHP 7 project

    ```
    devkit run php74 composer create-project --prefer-dist laravel/laravel projectdir
    ```

## Project Commands : run from top level project directory

-	Update dependencies for PHP7 project

	```
	devkit run php74 composer update
	```

-	Update dependencies for PHP5 project

	```
	devkit run php56 composer update
	```

-	Start a bash shell in the project
	```
	devkit exec php74 bash
	```

## Project Shortcut Commands : run from top level project directory

ADD `DEVKIT_SERVICE=php74` or `DEVKIT_SERVICE=php56` to the project's *.env* file.

-	Update dependencies

	```
	devkit composer update
	```

-	Run **artisan**

	```
	devkit ./artisan
	```

-	Run **npm**

	```
	devkit npm install
	```

-	Run **phpunit**

	```
	devkit ./vendor/bin/phpunit
	```

-	Launch **bash** in the project's container

	```
	devkit bash
	```



