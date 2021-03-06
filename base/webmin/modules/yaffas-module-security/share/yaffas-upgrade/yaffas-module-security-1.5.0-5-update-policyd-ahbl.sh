#!/bin/bash

# ADM-??? (ahbl.org been discontinued)
PERL5LIB=/opt/yaffas/lib/perl5/ perl -e '
if (!eval "use Yaffas::Module::Security; return 1") {
	# no yaffas? nothing todo...
	exit 0;
}

my @entries = Yaffas::Module::Security::policy_rhsbl();

while (@entries) {
	my ($host, $hit, $miss, $log) = splice(@entries, 0, 4);
	if ($host =~ /ahbl\.org$/) {
		print "Removing RHSBL entry $host (has been discontinued)\n";
		Yaffas::Module::Security::policy_delete_rhsbl($host, $hit, $miss, $log);
	}

}
'
