Summary:	Perl library for File::Samba
Name:		yaffas-lib-file-samba
Version:	1.1.4
Release:	1
License:	Perl
Group:		Applications/System
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	perl >= 5

%description
File::Samba - This module allows for easy editing of smb.conf in an OO way.

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/lib/perl5

%changelog
