#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')

if [[ $OS == RHEL* ]]; then
	cp -f -a /opt/yaffas/share/doc/example/etc/amavis/conf.d/60-yaffas /etc/amavis/conf.d/60-yaffas
else
	cp -f -a /opt/yaffas/share/doc/example/etc/amavis/conf.d/60-yaffas-debian /etc/amavis/conf.d/60-yaffas
fi
