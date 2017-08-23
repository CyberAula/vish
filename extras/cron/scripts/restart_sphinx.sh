#!/bin/bash

echo "Restart sphinx"

: ${RAILS_ENV="production"} #to get the environment variable or define it
: ${RAILS_ROOT="/u/apps/vish/current"}
: ${CAP_USER="capistrano"}

rvm_installed=false
if [ -s "$HOME/.rvm/scripts/rvm" ] || [ -s "/usr/local/rvm/scripts/rvm" ] || [ -s "/home/$CAP_USER/.rvm/scripts/rvm" ] ; then
	rvm_installed=true
	source /home/$CAP_USER/.rvm/scripts/rvm
fi

cd $RAILS_ROOT
SPHINX_COMMAND="-u $CAP_USER -H bundle exec rake ts:rebuild RAILS_ENV=$RAILS_ENV"
if $rvm_installed; then
	SPHINX_COMMAND="rvmsudo $SPHINX_COMMAND"
else
	SPHINX_COMMAND="sudo $SPHINX_COMMAND"
fi
$SPHINX_COMMAND

#fix sphinx pid file permissions
/bin/chmod 777 $RAILS_ROOT/log/searchd*
/bin/chown $CAP_USER:www-data $RAILS_ROOT/log/searchd*

echo "Task finished"