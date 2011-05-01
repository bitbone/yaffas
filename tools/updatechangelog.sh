#!/bin/bash

DEBEMAIL="packages@yaffas.org"
DEBFULLNAME="Package Builder"

DIR=$1; shift

pushd .

cd $(dirname $DIR)
cd ..

pwd

dch $*

popd
