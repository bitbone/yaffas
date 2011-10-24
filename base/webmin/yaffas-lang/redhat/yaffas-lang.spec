Summary:	Language files for webmin
Name:		yaffas-lang
Version:	1.0.0
Release:	1
License:	AGPLv3
Group:		Applications/System
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	perl, yaffas-core

%description
Language files for webmin

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%post -p /usr/bin/perl
my @langs = ("de", "en", "nl", "fr", "pt_BR");
my @path = qw(/opt/yaffas/webmin /opt/yaffas/usermin);

foreach my $path (@path) {
	next unless -d $path;
	foreach $lang (@langs) {
		my %content;
		my %newcontent;
		my $check = 1;
		my $file = "$path/lang/$lang";

		open FILE, "< /tmp/yaffas-lang/$lang" or die ("Can't open file: $!");
		my @tmp = <FILE>;

		foreach my $value (@tmp) {
			my @values = split "=", $value, 2;
			if (defined($values[1])) {
				chomp $values[1];
				$newcontent{$values[0]} = $values[1];
			}
		}
		close FILE;

		open FILE, "< $file" or $check = 0;

		if ($check == 0) {
			print "Couldn't open file: $!";
			exit 0;
		}

		@tmp = <FILE>;
		close FILE;

		foreach my $value (@tmp) {
			my @values = split "=", $value;
			if (defined($values[1])) {
				chomp $values[1];
				$content{$values[0]} = $values[1];
			}
		}

		foreach my $key (keys %newcontent) {
			$content{$key} = $newcontent{$key};
		}

# Fehler bei install: Couldn't open file: Datei oder Verzeichnis nicht gefunden
		open FILE, "> $file" or $check = 0;
		foreach my $key (sort keys %content) {
			print FILE "$key=$content{$key}\n";
			print $key unless(defined($content{$key}));
		}
		close FILE;
	}
}

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}

/tmp/yaffas-lang/*
%dir /tmp/yaffas-lang

%changelog
