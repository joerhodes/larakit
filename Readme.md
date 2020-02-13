# Welcome

This document outlines the steps for setting up a functioning development environment for **macOS Catalina**.  This document is written for a fresh, clean install of **Catalina**.  If your system is not on **Catalina**, go upgrade.  If your system is not a clean install, some of the following steps may be unnecessary or may conflict with existing software.  It is your responsibility to solve and document these cases.

## Basics

1. 	Every system needs **git**
	
	Open **terminal** and type `git --version`.  If **git** is already installed, the version will be displayed.  Otherwise, the system will prompt you to install the **XCode** command line tools.  Do so.
	
1.	Install [Fork](https://fork.dev)

1.	Install [Docker for Mac](https://www.docker.com/docker-mac)

1.	Disable Docker's Idle Network Connection Timeout

	Add `"vpnKitPortMaxIdleTime": 0` to *~/Library/Group Containers/group.com.docker/settings.json*.
	
        {
            "diskSizeMiB" : 61035,
            "memoryMiB" : 2048,
            "dockerAppLaunchPath" : "/Applications/Docker.app",
            "displayedWelcomeMessage" : true,
            "settingsVersion" : 1,
            "buildNumber" : "29268",
            "proxyHttpMode" : "system",
            "channelID" : "stable",
            "version" : "2.0.0.0-mac82",
            "cpus" : 4,
            "linuxDaemonConfigCreationDate" : "2018-08-02 13:43:59 +0000",
            "displayedWelcomeWhale" : true,
            "diskPath" : "Library/Containers/com.docker.docker/Data/vms/0/Docker.raw",
            "vpnKitPortMaxIdleTime": 0
        }

	After installation, use either the command line or the menu bar to login into Docker Cloud with your FuseMind email address.

1.	Import `LI Styles20171011.xml` into PHPStorm

1.	Follow [macOS Setup Guide](Instructions.md)

1.	Checkout this project to your local system, eg `~/Sites/larakit`

1.	Add the checkout location to your shell search path

		export PATH=$PATH:~/Sites/larakit


1.	Use `larakit` as a replacement for `docker-compose`

		[~/Sites/project] $ larakit exec composer update

	[More information about **larakit**](larakit-commands.md)

1.	Set Up Dependencies for [LeadForce 2](LeadForce2.md)
