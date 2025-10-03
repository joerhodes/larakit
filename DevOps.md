# DevOps - New Deployments

Larakit now provides 2 scripts to help with application deployments.  This document describes how to use them and
what the currently replace.

**NOTE** These scripts require the deploy SSH ky under the `keys` folder.

### Current Deployment Steps

Most of our applications are deployed procedure similar to the following:

```shell
scp deploy.id_rsa SERVER:
ssh SERVER
sudo useradd -m -s /usr/bin/bash fmorder
sudo mkdir /home/fmorder/.ssh
sudo mv deploy.id_rsa /home/fmorder/.ssh/id_rsa
sudo chown -R fmorder:fmorder /home/fmorder/.ssh
sudo su - fmorder
chmod -R go-rwx .ssh
### Start of Envoyer Deployment steps
mkdir -p from-ddg/archive
mkdir fmorder
git clone git@bitbucket.org:fusemind/fmorder.git fmorder
cd fmorder
git checkout develop|branch|tag
cp .env.exmaple .env
# you must edit .env here
#
# NOTE:
#     If deploy.sh step fails AND the JWT_SECRET is empty in the environment file,
#     run ./artisan jwt:secret and the ./deploy.sh -a 
./deploy.sh -a
./artisan key:generate
./nginxconfig
### End of Envoyer Deployment steps
exit
sudo chmod go+rx /home/fmorder
sudo cp /home/fmorder/current/resources/supervisord/fmorder.ini /etc/supervisor/conf.d/fmorder.conf
sudo systemctl restart supervisor
# use sudo systemctl status to ensure fmorder worker is running
sudo cp /home/fmorder/current/php-fpm.conf /etc/php/8.3/fpm/pool.d/fmorder.conf
sudo php-fpm8.3 -t
sudo systemctl restart php8.1-fpm
# use sudo systemctl status to ensure FPM is running for fmorder
sudo cp /home/fmorder/current/nginx.{env}.conf /etc/nginx/sites-available/fmorder.conf
sudo ln -s /etc/nginx/sites-available/fmorder.conf /etc/nginx/sites-enabled/fmorder.conf
sudo nginx -t
sudo systemctl restart nginx
```

### New Deployment Script

Two new scripts are provided to help simplify this procedure.

- The `createApplicationUser.sh` script will create the application user on the target server.
  The user account will be set up to run `composer` as needed.  It will also be able to restart
  the `php-fpm` service.
- The `postFirstDeployment.sh` script will finish the initial deployment by configuring the required
  services: NGINX, PHP-FPM and Supervisor.  Each service that application provides a configuration
  file for will be updated and restarted.

### New Deployment Example


And exmple of the new deployment process is provided below:

- `createApplicationUser.sh dev83.fusemind.dev fmorder`
- Set up Envoyer for server dev83.fusemind.dev, environment variables and deployment hooks.
- Manually trigger Envoyer to deploy the `develop` branch.
- `postFirstDeployment.sh dev83.fusemind.dev fmorder`

