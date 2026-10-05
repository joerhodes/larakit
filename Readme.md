# larakit

A shell-script toolkit for **macOS** that wraps [Laradock](https://laradock.io) to provide a simple, consistent command-line interface for local Laravel development and deployment.

## Why

Laradock is powerful, but its raw docker-compose workflow has a real learning curve — especially for a team without much Docker experience. larakit was built to hide that complexity behind a small set of memorable commands (`larakit up`, `larakit switch 8.3`, `larakit register project.test`) while still leaving full docker-compose access available when it's actually needed. The goal is a local environment that "just works" for day-to-day development, without requiring every engineer to become a Docker expert first.

## Origin

I wrote and maintained larakit as internal tooling at FuseMind, giving our
team local Docker environments that mirrored our production setup. It is
published here with FuseMind's permission. The original commit history is
preserved; commits from the `public-release` tag onward cover the cleanup
for public use.

## Repository Structure

| Path | Description |
|---|---|
| `lib/` | Modular shell library sourced by the `larakit` command. Each area of functionality (Laradock management, service stack control, hostname aliasing, deployment) lives in its own module. |
| `tests/` | [BATS](https://github.com/bats-core/bats-core) test suite covering the `lib/` modules. |
| `config/` | Override and injection files layered on top of the stock Laradock configuration. |
| `keys/` | Deploy keys used by the deployment scripts. |
| `laradock/` | Local checkout of Laradock — the docker-compose stack larakit wraps. |
| `docs/` | Full documentation set, linked below. |

## Getting Started

**Requires macOS** — larakit relies on macOS-specific tooling (`dnsmasq` DNS configuration, the macOS Keychain for SSH key handling) and hasn't been tested on Linux or Windows.

- [macOS setup guide](docs/setup-macos.md) — installing dependencies and checking out the project
- [dnsmasq / DNS setup guide](docs/dnsmasq-setup.md) — local `.test` domain resolution, and fixing DNS issues after a VPN reconnects
- [Command reference](docs/commands.md) — full list of `larakit` subcommands

## Deployment

Beyond local development, larakit includes two scripts for provisioning and deploying to remote servers:

- `createApplicationUser.sh` — creates a scoped application user on a target server, permitted to run `composer` and restart `php-fpm`
- `postFirstDeployment.sh` — configures NGINX, PHP-FPM, and Supervisor for a newly deployed application

See [Deployment](docs/deployment.md) for the full walkthrough.

## Testing

The `lib/` modules are covered by a [BATS](https://github.com/bats-core/bats-core) test suite in `tests/`, written alongside the modules themselves as they were built out.

**Current coverage:** two of the library modules have solid test coverage, though both are likely to gain new functions over time. The top-level `larakit` script itself has minimal coverage so far — help output, and hostname alias registration/deregistration. Coverage for the remaining modules and commands is being added incrementally.

Run `addTestFramework.sh` once to install BATS and its helper libraries, then run the suite with:

```bash
./test/bats/bin/bats tests/
```
