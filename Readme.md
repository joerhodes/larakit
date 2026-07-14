# Welcome

This document outlines the steps for setting up a functioning development environment for **macOS**.  This document is written for a fresh, clean install of **macOS**.  If your system is not on the most recent version, it is recommended to upgrade first.  If your system is not a clean install, some of the following steps may be unnecessary or may conflict with existing software.  It is your responsibility to solve and document these cases.

## Basics

1. 	Every system needs **git**
	
	Open **terminal** and type `git --version`.  If **git** is already installed, the version will be displayed.  Otherwise, the system will prompt you to install the **XCode** command line tools.  Do so.
	
1.	Install [Fork](https://fork.dev)

1.	Install [Docker for Mac](https://www.docker.com/docker-mac)

1.  Increase Docker Resources

    Open Docker icon on the *Apple menu bar*, click on *Preference*, open *Resources > Advanced*, set up CPU with 4 at least, Memory with 8.00 GB, then click on *Apply & Restart*. 

1.	Disable Docker's Idle Network Connection Timeout

	Find `"vpnKitPortMaxIdleTime"` in the `~/Library/Group Containers/group.com.docker/settings.json` file.  The value needs to set 0.  If the settings key doest not exists, add it.

	Restart Docker and then use either the command line or the menu bar to login into Docker Cloud with your FuseMind email address.

1.	Import `phpstorm_code_style_20211208.xml` into PHPStorm and set as the default.

1.	Follow [macOS Setup Guide](Instructions.md)

1.	Checkout this project to your local system, eg `~/Sites/larakit`

1.	Add the checkout location to your shell search path in either `~/.bashrc` or `~/.zshrc`

		export PATH=$PATH:~/Sites/larakit
	Then start a new terminal and verify the **PATH** variable.
		
1.	Install [Laradock](https://laradock.io)

		larakit laradock install
		
1. Next you should build the containers for the version of PHP that you need to work with.

		larakit switch 8.3

## Platform Setup:

1. LeadForce PRO:

    Please follow [LeadForcePro Initial Deployment](https://bitbucket.org/fusemind/lfpro/src/master/docs/InitialDeployment.md)


## General Usage (to replace devkit):

1. Run docker: `larakit up`
1. Shut down docker: `larakit down`
1. Run bash in a running container: `larakit exec bash`
1. Update composer can be run inside the docker container with `larakit exec composer update`
1. Add project host names `larakit register project.test`
1. See more information about  [full list of **larakit** commands](larakit-commands.md)

## Testing Database Server

Our team use **Postgres.app** for local development databases. For testing with **PHPUnit**, you can provision a dedicated **test server** to achieve isolation from your main project databases. To do so:

1. Open **Postgres.app** by clicking the program's logo on the top Menu Bar.
1. On the left sidebar, click on the **+** button at the bottom.
1. Specify your new server's **Name** (such as `Test Server`) and a different **Port** (such as `5433`), then click **Create Server**.

If your project runs on Laravel, just edit the `.env.testing` file and set the `DB_PORT` key to the correct port (such as `5433`). Now you can run PHPUnit with this dedicated test server.

## SFTP Testing

If you need to test SFTP connection and file transfers, add the `sftpservice` to your list of 
default services in your `configs/environment` file.  This service provides an SFTP server that
is available as the host `sftpserver` with a username / password of `demo` / `demo`.  More information
about this service can be found here https://hub.docker.com/r/emberstack/sftp.

## Upgrading

The follow steps outline the procedure to follow with upgrading Larakit to a new version. 
Some of these steps may take a moment = be patient.

```shell
cd ~/Sites/larakit
larakit down
git fetch
git checkout NEW_TAG
docker rmi -f $(docker images 'laradock*' -q)
docker image prune -f
docker container prune -f
docker buildx prune -f 
docker volume prune -f
docker system prune -a
larakit laradock update
larakit switch PHP_VERSION
larakit up
```

**NOTE** If there are containers that fail to start after upgrading, you may need to remove files under `~/.laradock`.
