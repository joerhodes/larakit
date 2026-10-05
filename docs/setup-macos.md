# macOS Setup

This document outlines the steps for setting up a functioning development environment for **macOS**. It is written for a fresh, clean install of **macOS**. If your system is not on the most recent version, it is recommended to upgrade first. If your system is not a clean install, some of the following steps may be unnecessary or may conflict with existing software — it is your responsibility to resolve and document those cases.

## OS Setup

These steps happen once per machine, before checking out any project.

1. 	Every system needs **git**.

	Open **terminal** and type `git --version`. If **git** is already installed, the version will be displayed. Otherwise, the system will prompt you to install the **Xcode** command line tools. Do so.

1.	Install [Docker for Mac](https://www.docker.com/docker-mac).

1.  Increase Docker's resource limits.

    Open the Docker icon on the *Apple menu bar*, click *Preferences*, open *Resources > Advanced*, set CPU to at least 4 and Memory to at least 8.00 GB, then click *Apply & Restart*.

1.	Disable Docker's idle network connection timeout.

	Find `"vpnKitPortMaxIdleTime"` in the `~/Library/Group Containers/group.com.docker/settings.json` file and set the value to `0`. If the key doesn't exist, add it.

	Restart Docker, then log in to Docker Hub from either the command line or the menu bar using your Docker account credentials.

1.	Follow the [dnsmasq / DNS setup guide](dnsmasq-setup.md).

## larakit Setup

These steps happen once per project checkout.

1.	Check out this project to your local system, e.g. `~/Sites/larakit`.

    1.	Add the checkout location to your shell search path in either `~/.bashrc` or `~/.zshrc`:

        ```
		export PATH=$PATH:~/Sites/larakit
        ```

        Start a new terminal and verify the **PATH** variable.

1.	Verify local dependencies and install [Laradock](https://laradock.io):

    ```bash
    larakit depCheck
    larakit laradock install
    ```

1.	Generate the local `configs/environment` file:

		larakit env reset

	This creates `configs/environment` with larakit's default feature flags for the Laradock workspace and PHP-FPM containers. Review the generated file and adjust any `WORKSPACE_INSTALL_*` or `PHP_FPM_INSTALL_*` values before your first build — changing any of them later requires rebuilding the containers. `configs/environment` is gitignored, since it's local/machine-specific configuration rather than project source.

1. 	Build the containers for the PHP version you need to work with:

		larakit switch 8.3

## General Usage

1. Run docker: `larakit up`
1. Shut down docker: `larakit down`
1. Run bash in a running container: `larakit exec bash`
1. Update composer inside the docker container: `larakit exec composer update`
1. Add a project hostname alias: `larakit register project.test`
1. See the [full list of larakit commands](commands.md) for more.

## SFTP Testing

If you need to test SFTP connections and file transfers, add `sftpserver` to the list of default services in your `configs/environment` file. This service provides an SFTP server available at the host `sftpserver` with a username / password of `demo` / `demo`. More information on this service is available [here](https://hub.docker.com/r/emberstack/sftp).

## Upgrading

The following steps outline the procedure for upgrading larakit to a new version. Some steps may take a moment — be patient.

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
larakit depCheck
larakit laradock update
larakit switch PHP_VERSION
larakit up
```

**Note:** If any containers fail to start after upgrading, you may need to remove the files under `~/.laradock`.
