#!/bin/bash

# ADM-246
sed -re 's:rfc-ignorant\.org:rfc-ignorant.de:g' -i /etc/policyd-weight.conf
