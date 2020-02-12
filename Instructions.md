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

        $ ping -c 1 nohost.test
        PING nohost.test (127.0.0.1): 56 data bytes
        64 bytes from 127.0.0.1: icmp_seq=0 ttl=64 time=0.034 ms
        
        --- nohost.test ping statistics ---
        1 packets transmitted, 1 packets received, 0.0% packet loss
        round-trip min/avg/max/stddev = 0.034/0.034/0.034/0.000 ms
        
        $ ping -c 1 nohost.lo
        PING nohost.lo (127.0.0.1): 56 data bytes
        64 bytes from 127.0.0.1: icmp_seq=0 ttl=64 time=0.040 ms
        
        --- nohost.lo ping statistics ---
        1 packets transmitted, 1 packets received, 0.0% packet loss
        round-trip min/avg/max/stddev = 0.040/0.040/0.040/0.000 ms
	
1.	Checkout [uber-common/docker-ssh-agent-forward](https://github.com/uber-common/docker-ssh-agent-forward.git) to a top level directory.

1.	Build the ssh-agent containter.

	    $ cd docker-ssh-agent-forward
	    $ make
	    $ sudo make install

1.  Create directory `~/SitesHome/`  This directory is mapped to `/home` in the container.

1.  Create directory `~/SitesLogs/`  This is mapped to `/var/log/httpd` in the container.

1.  Clean out all of the files under `~/Sites/sessions`.

    	$ sudo rm ~/Sites/sessions/*/sess*

1.  Make sure any symbolic links under `~/Sites` are relatively path'd.

        $ cd ~/Sites
        $ ls -l symfony
        lrwxr-xr-x  1 jrhodes  staff  16 Sep  7 10:42 symfony -> /Users/jrhodes/Sites/Includes/symfony
        $ rm symfony
        $ ln -s Includes/symfony symfony
        $ ls -l symfony
        lrwxr-xr-x  1 jrhodes  staff  16 Sep  7 10:42 symfony -> Includes/symfony

1.  Ensure directory `~/Sites/public` exists. This path is used by the PHP containers at the default path. If you have `~/Sites/html`, rename to `~/Sites/public`.
