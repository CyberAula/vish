#!/bin/bash

#A script to automatically load a postgresql dump into the database.
#If no argument is provided, it will load the latest dump. Otherwise, it will try to load the file pass as argument.

if [ -z "$1" ]
then
  #Get last dump
  dumpFile=`find . -type f -name "*.sql" -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" "`
else
  dumpFile=$1
fi

if [ -f $dumpFile ];
then
   #echo "Loading :" $dumpFile
   echo
else
   echo "File $dumpFile does not exist."
   exit 1
fi

read -p "The dump $dumpFile is going to be restored into your database. Are you sure? (Type 'y' to continue) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

sudo -u postgres dropdb vish_production
sudo -u postgres createdb vish_production
sudo -u postgres psql vish_production < $dumpFile
