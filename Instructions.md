## Dockerized Development Kit for macOS

1.  Stop Apache

    ```
    $ sudo apachectl stop
    ```

1.	Install [Homebrew](https://brew.sh)

1.	Install dsnmasq

    ```
	brew install dnsmasq
    ```
	    
1.	Add the install path of dnsmasq to your PATH in your startup file, either `~/.bashrc` or `~/.zshrc`.

    ```
	export PATH=$PATH:/opt/homebrew/sbin
    ```
	
	The install path on your system maybe different.

1.	Add the following lines to `/opt/homebrew/etc/dnsmasq.conf`.  If this file does not exist, try this path `/usr/local/etc/dnsmasq.conf`.  

    ```    
    # Listen on all interfaces (so Docker Desktop VM can reach it)
    listen-address=0.0.0.0,127.0.0.1

    # Local dev domains
    address=/.test/127.0.0.1
    address=/.test/::1
    address=/.lo/127.0.0.1
    ```

1.	Create the DNS resolvers

    ```
    sudo mkdir -v /etc/resolver
    sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/lo'
    sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/test'
    ```

1.	Start dsnmasq service.   **Note** You may need to run this twice.

    ```
	sudo brew services start dnsmasq
    ```

1.	Clear local DNS cache.

    ```
	dscacheutil -flushcache
	sudo killall -HUP mDNSResponder
    ```
	
1.	Verify that .test and .lo requests are using 127.0.0.1

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
	
1.	Test with ping:
        ```
        $ ping -c 1 admin.leadforcepro.lo
        PING admin.leadforcepro.lo (127.0.0.1): 56 data bytes
        64 bytes from 127.0.0.1: icmp_seq=0 ttl=64 time=0.031 ms
        
        --- admin.leadforcepro.lo ping statistics ---
        1 packets transmitted, 1 packets received, 0.0% packet loss
        round-trip min/avg/max/stddev = 0.031/0.031/0.031/0.000 ms
        ```
     
        ```
        $ ping -c 1 admin.leadforcepro.test
        PING admin.leadforcepro.test (127.0.0.1): 56 data bytes
        64 bytes from 127.0.0.1: icmp_seq=0 ttl=64 time=0.025 ms
        
        --- admin.leadforcepro.test ping statistics ---
        1 packets transmitted, 1 packets received, 0.0% packet loss
        round-trip min/avg/max/stddev = 0.025/0.025/0.025/0.000 ms
         ```
 
1.  Update Docker Desktop to use `dsnmasq` as DNS server.  This will prevent name resolution issues when the
    when the VPN status changes.

    Get the IP address that docker containers are using for DNS look ups.

    ```
    docker run --rm alpine:3.23 sh -lc 'nslookup host.docker.internal'
    ```
    
    Now make sure Docker Desktop -> Settings -> Docker Engine contains:

    `"dns": ["<Reported IP Address>"]`

    Next Restart Docker Desktop.

    > **Note** This step only needs to be redone if Docker Desktop’s internal VM is recreated.
    This can happen if Docker Desktop is factory-reset, fully uninstalled/reinstalled, or in 
    rare cases after a major Docker Desktop upgrade. Routine actions such as rebuilding images, 
    pruning containers/volumes, switching PHP versions, or updating Laradock do not require 
    repeating this step.

1.  Create directory `~/Sites/` if does not exist. All your website repository needs to be under this folder.

1.  Create directory `~/SitesHome/` if does not exist. This directory is mapped to `/home2` in the container.

