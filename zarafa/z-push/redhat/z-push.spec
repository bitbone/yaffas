Name:		z-push
Version:	1.4
Release:	1%{?dist}
Summary:	Open-source push technology
Group:		Applications/System
License:	GPL
Source0:	file://%{name}-%{version}.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch:	noarch
Requires:	php, php-pear

%description
Z-push is an implementation of the ActiveSync protocol, which is used 'over-the-air' for
multi platform ActiveSync devices, including Windows Mobile, Ericsson and Nokia phones.
With Z-push any groupware can be connected and synced with these devices.

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}
/var/www/z-push


%changelog
* Thu Mar 03 2011 Sebastian Stumpf <stumpf@bitbone.de> 1.4-1
- Updated the build system
