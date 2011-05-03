#!/bin/bash

DEBEMAIL="packages@yaffas.org"
DEBFULLNAME="Package Builder"

DIR=$1; shift

pushd .

cd $(dirname $DIR)
cd ..

pwd

dch $1 $2 $3; shift; shift; shift

for var in "$@"; do
	dch "$var"
done

popd
