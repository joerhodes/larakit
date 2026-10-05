## Dockerized Development Kit for macOS

1.	Install [Homebrew](https://brew.sh).

1.	Install dnsmasq:

    ```
	brew install dnsmasq
    ```

1.	Add the install path of dnsmasq to your `PATH` in your startup file, either `~/.bashrc` or `~/.zshrc`:

    ```
	export PATH=$PATH:/opt/homebrew/sbin
    ```

	The install path on your system may differ.

1.	Add the following lines to `/opt/homebrew/etc/dnsmasq.conf`. If this file does not exist, try `/usr/local/etc/dnsmasq.conf`.

    ```
    # Listen on all interfaces (so Docker Desktop VM can reach it)
    listen-address=0.0.0.0,127.0.0.1

    # Local dev domains
    address=/.test/127.0.0.1
    address=/.test/::1
    ```

1.	Create the DNS resolvers:

    ```
    sudo mkdir -v /etc/resolver
    sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/lo'
    sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/test'
    ```

1.	Start the dnsmasq service. **Note:** you may need to run this twice.

    ```
	sudo brew services start dnsmasq
    ```

1.	Clear the local DNS cache:

    ```
	dscacheutil -flushcache
	sudo killall -HUP mDNSResponder
    ```

1.	Verify that `.test` requests resolve to `127.0.0.1`:

    ```
	scutil --dns
    ```

	You should see something like:

        resolver #8
	        domain   : test
            nameserver[0] : 127.0.0.1
	        flags    : Request A records, Request AAAA records
	        reach    : 0x00030002 (Reachable,Local Address,Directly Reachable Address)

        resolver #9
	        domain   : lo
	        nameserver[0] : 127.0.0.1
	        flags    : Request A records, Request AAAA records
	        reach    : 0x00030002 (Reachable,Local Address,Directly Reachable Address)

1.  Update Docker Desktop to use dnsmasq as its DNS server. This prevents name resolution issues when VPN status changes.

    Get the IP address that docker containers use for DNS lookups:

    ```
    docker run --rm alpine:3.23 sh -lc 'nslookup host.docker.internal'
    ```

    Then confirm Docker Desktop → Settings → Docker Engine contains:

    `"dns": ["<Reported IP Address>"]`

    Restart Docker Desktop afterward.

    > **Note:** This step only needs to be redone if Docker Desktop's internal VM is recreated. This can happen if Docker Desktop is factory-reset, fully uninstalled/reinstalled, or in rare cases after a major Docker Desktop upgrade. Routine actions such as rebuilding images, pruning containers/volumes, switching PHP versions, or updating Laradock do not require repeating this step.

1.  Create the `~/Sites/` directory if it does not already exist. All website repositories need to live under this folder.
