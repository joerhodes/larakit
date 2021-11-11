# LeadForce 2 Dependencies

This document describes the process of installing the dependencies needed by the LeadForce 2 application.  These are system dependencies instead of project dependencies and thus need to be placed outside of the LeadForce 2 project directory.

1.	Install and Update YUI
        
        $ cd ~/Sites
        $ rm -rf yui
        $ git clone ssh://git@bitbucket.org/fusemind/yui-vhost.git yui
        $ cd yui
        $ devkit run php56 composer install
        

1.	~~Install Legacy PHP Libraries~~ 

	These libraries should be part of the project's `composer.json` dependencies.
        
        $ cd ~/Sites
        $ mkdir Includes
        $ cd Includes
        $ git clone ssh://git@bitbucket.org/fusemind/zend.git Zend
        $ git clone ssh://git@bitbucket.org/fusemind/adodb.git adodb
        $ mkdir phpseclib
        $ cd phpseclib
        $ git clone ssh://git@bitbucket.org/fusemind/phpseclib.git phpseclib
        $ cd ..
        $ git clone ssh://git@bitbucket.org/fusemind/sferrornotifierplugin.git sfErrorNotifierPlugin
        $ git clone ssh://git@bitbucket.org/fusemind/sfguardextraplugin.git sfGuardExtraPlugin
        $ git clone ssh://git@bitbucket.org/fusemind/sfguardplugin.git sfGuardPlugin
        $ git clone ssh://git@bitbucket.org/fusemind/symfony.git symfony
        $ cd ..
        $ ln -s Includes/symfony symfony
        
