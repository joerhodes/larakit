## Dockerized Dev Kit for macOS Catalina

1.  Stop Apache

    	$ sudo apachectl stop

1.	Install [Homebrew](https://brew.sh)

1.	Install dsnmasq

	    $ brew install dnsmasq

1.	Add the following line to `/usr/local/etc/dnsmasq.conf`

	    address=/.test/127.0.0.1
	    address=/.lo/127.0.0.1

1.	Create the DNS resolvers

        sudo mkdir -v /etc/resolver
        sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/lo'
        sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/test'

1.	Start dsnmasq service.   **Note** You may need to run this twice.

	    sudo brew services start dnsmasq

1.	Clear local DNS cache.

	    sudo killall -HUP mDNSResponder
	
1.	Verify that .test and .lo requests are using 127.0.0.1

	    scutil --dns
	
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
      
1.	Checkout [uber-common/docker-ssh-agent-forward](https://github.com/uber-common/docker-ssh-agent-forward.git) to a top level directory.

1.	Build the ssh-agent container.

	    $ cd docker-ssh-agent-forward
	    $ make
	    $ sudo make install
	    
1.  Create directory `~/Sites/` if does not exist. All your website repository needs to be under this folder.

1.  Create directory `~/SitesHome/` if does not exist. This directory is mapped to `/home` in the container.

1.  Create directory `~/SitesLogs/` if does not exist. This is mapped to `/var/log/httpd` in the container.

1.  Create directory `~/Sites/sessions` if does not exist. If existed, please clean it up by running `$ sudo rm ~/Sites/sessions/*/sess*`.
