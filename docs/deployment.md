# DevOps: New Deployments

Larakit provides two scripts to help with application deployments. This document describes how to use them and what they replace.

**Note:** These scripts require the deploy SSH key under the `keys` folder.

### Deployment Scripts

Two scripts simplify this procedure:

- `createApplicationUser.sh` creates the application user on the target server. The account is set up to run `composer` as needed, and is permitted to restart the `php-fpm` service.
- `postFirstDeployment.sh` finishes the initial deployment by configuring the required services — NGINX, PHP-FPM, and Supervisor. Each service for which the application provides a configuration file will be updated and restarted.

### Deployment Example

An example of the deployment process is provided below:

- `createApplicationUser.sh remote.server.com app-user`
- Set up Envoyer for `remote.server.com` — environment variables and deployment hooks.
- Manually trigger Envoyer to deploy the `develop` branch.
- `postFirstDeployment.sh remote.server.com app-user`
