#!/bin/bash

echo "[Start] ViSH check daemons script"

: ${RAILS_ENV="production"} #to get the environment variable or define it
: ${RAILS_ROOT="/u/apps/vish/current"}
: ${SPHINX_PID_FILE="$RAILS_ROOT/log/searchd.$RAILS_ENV.pid"} 
: ${GOD_PID_FILE="/var/run/god/resque-worker-0.pid"}
: ${CAP_USER="capistrano"}

check_sphinx=false
check_god=false

if [ $# -eq 0 ]; then
	check_sphinx=true
	check_god=true
else
	for ARG in $*
	do
		if [ $ARG = "sphinx" ]; then
			check_sphinx=true
		elif [ $ARG = "god" ]; then
			check_god=true
		fi
	done
fi

rvm_installed=false
if [ -s "$HOME/.rvm/scripts/rvm" ] || [ -s "/usr/local/rvm/scripts/rvm" ] || [ -s "/home/$CAP_USER/.rvm/scripts/rvm" ] ; then
	rvm_installed=true
	source /home/$CAP_USER/.rvm/scripts/rvm
fi


if $check_sphinx; then
	run_sphinx=false
	if test -f $SPHINX_PID_FILE; then
		sphinx_ps="$(ps -p `cat $SPHINX_PID_FILE` -o comm=)"
		if [ "$sphinx_ps" != "searchd" ]; then
			run_sphinx=true
			rm $SPHINX_PID_FILE
		fi
	else
		run_sphinx=true
	fi

	if $run_sphinx; then
		echo "Let's run sphinx!"
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
	else
		echo "Sphinx already running"
	fi
fi


if $check_god; then
	run_god=false
	if test -f $GOD_PID_FILE; then
		god_ps="$(ps -p `cat $GOD_PID_FILE` -o comm=)"
		if [ "$god_ps" != "ruby" ]; then
			run_god=true
			sudo rm -f $GOD_PID_FILE
		fi		
	else
		run_god=true
	fi

	if $run_god; then		
		echo "Let's run god!"
		GOD_COMMAND="god -c $RAILS_ROOT/config/resque.god"
		if $rvm_installed; then
			GOD_COMMAND="rvmsudo $GOD_COMMAND"
		else
			GOD_COMMAND="sudo $GOD_COMMAND"
		fi
		$GOD_COMMAND
	else
		echo "God already running"
	fi
fi

echo "[Finish] ViSH check daemons script"