# Welcome

This document outlines the steps for setting up a functioning development environment for **macOS Big Sur**.  This document is written for a fresh, clean install of **Big Sur**.  If your system is not on **Big Sur**, go upgrade.  If your system is not a clean install, some of the following steps may be unnecessary or may conflict with existing software.  It is your responsibility to solve and document these cases.

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

1.	Import `LI Styles20171011.xml` into PHPStorm

1.	Follow [macOS Setup Guide](Instructions.md)

1.	Checkout this project to your local system, eg `~/Sites/larakit`

1.	Add the checkout location to your shell search path

		export PATH=$PATH:~/Sites/larakit
		
1.	Install [Laradock](https://laradock.io)

		larakit laradock install
		
1. You do *NOT* need to run `larkit build` since it is built, please follow *Platform Setup* section below to set up the dedicated platforms you needed. Once all setup is done, you just need to run `larakit up`. See below *General Usage* section.

## Platform Setup:

1. LeadForce PRO:

    Please follow [LeadForcePro Initial Deployment](https://bitbucket.org/fusemind/lfpro/src/master/docs/InitialDeployment.md)

1. LeadForce 2:

    Please follow [LeadForce 2](LeadForce2.md) to setup all LF2 dependencies such as YUI
        

## General Usage (to replace devkit):

1. Run docker: `larakit up`
1. Shut down docker: `larakit down`
1. Run bash in docker image: `larakit run bash`
1. Update composer can be inside the docker with `composer update` or outside with `larakit run composer update`
1. See more information about  [full list of **larakit** commands](larakit-commands.md)

## Testing Database Server

Our team use **Postgres.app** for local development databases. For testing with **PHPUnit**, you can provision a dedicated **test server** to achieve isolation from your main project databases. To do so:

1. Open **Postgres.app** by clicking the program's logo on the top Menu Bar.
1. On the left sidebar, click on the **+** button at the bottom.
1. Specify your new server's **Name** (such as `Test Server`) and a different **Port** (such as `5433`), then click **Create Server**.

If your project runs on Laravel, just edit the `.env.testing` file and set the `DB_PORT` key to the correct port (such as `5433`). Now you can run PHPUnit with this dedicated test server.
