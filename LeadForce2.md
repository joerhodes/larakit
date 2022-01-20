# LeadForce 2 Dependencies

This document describes the process of installing the dependencies needed by the LeadForce 2 application.  These are system dependencies instead of project dependencies and thus need to be placed outside of the LeadForce 2 project directory.

1.	Install and Update YUI
        
        cd ~/Sites
        rm -rf yui
        git clone ssh://git@bitbucket.org/fusemind/yui-vhost.git yui
        cd yui
        larakit composer install
        

1.	~~Install Legacy PHP Libraries~~ 

	These libraries should be part of the project's `composer.json` dependencies.
        
        
