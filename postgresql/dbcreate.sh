#!/bin/bash

VERSION="2"

### This script makes an assumption that you have a local .pgpass file which will allow
### psql and pg_restore to connect to the database server you are attempting to create
### as the postgres user.

DB=""
USER=""
PASSWORD=""
HOST=""
PORT=""

function usage() {
	echo "$0 v.${VERSION}"
	echo "Usage $0 [OPTION]"
	printf "  %s %-20s%s\n" "-d" "[DB]" "Database name to create"
	printf "  %s %-20s%s\n" "-u" "[USER]" "User to create"
	printf "  %s %-20s%s\n" "-w" "[PASSWORD]" "Password for the user"
	printf "  %s %-20s%s\n" "-s" "[HOST]" "Database host; default localhost"
	printf "  %s %-20s%s\n" "-p" "[PORT]" "Database port; default 5432"
	printf "  %s %-20s%s\n" "-h" "" "Prints this menu"
}

# Read CLI arguments
while getopts ":d::u::w::h" opt; do
	case $opt in
		d)
			DB=$OPTARG
		;;
		u)
			USER=$OPTARG
		;;
		w)
			PASSWORD=$OPTARG
		;;
		s)
			HOST=$OPTARG
		;;
		h)
			usage
			exit 0
		;;
	esac
done

# Validate CLI arguments

if [ -z ${DB} ]; then
	echo "Option -d is required"
	exit 1
fi
if [ -z ${USER} ]; then
	echo "Option -u is required"
	exit 1
fi
if [ -z ${PASSWORD} ]; then
	echo "Option -w is required"
	exit 1
fi
if [ -z ${HOST} ]; then
	HOST="localhost"
fi
if [ -z ${PORT} ]; then
	PORT="5432"
fi

# Error on unset variables
set -u

# If the database and user exist, we need to drop them
psql -U postgres -c "drop database ${DB}"
psql -U postgres -c "drop user ${USER}"

# Exit on error
set -e

# Create the user and database and setup permissions
psql -U postgres -c "create user ${USER} with encrypted password '${PASSWORD}' nocreatedb nocreateuser"
psql -U postgres -c "create database ${DB}"
psql -U postgres -c "grant all on database ${DB} to ${USER}"


# Flyway can't handle extensions like cube
extensions=$(psql -U postgres ${DB} -t -c "\dx" | awk '{print $1}' | sort -r)
for i in ${extensions}; do
	echo "dropping extension ${i}"
	psql -U postgres ${DB} -c "drop extension \"${i}\" cascade"
done
