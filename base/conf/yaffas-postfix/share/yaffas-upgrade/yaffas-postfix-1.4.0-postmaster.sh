#!/bin/bash
# see ADM-364
set -e
CFG=/etc/postfix/virtual_users_global
sed -re 's:^/(root|postmaster|FaxMaster)@.*/ :/^\1@.*/ :g' -i $CFG
postmap "$CFG"
