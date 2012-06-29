Summary:		perl yaffas library
Name:			yaffas-lib
Version:		1.0.0
Release:		1
License:		yaffas
Group:			Applications/System
Url:			http://www.yaffas.org
Source:			file://%{name}-%{version}.tar.gz
BuildArch:		noarch
BuildRoot:		%{_tmppath}/%{name}-%{version}-%{release}-buildroot
BuildRequires:	perl(ExtUtils::MakeMaker)
Requires:		perl >= 5, perl(Sort::Naturally), perl(Algorithm::Dependency), yaffas-lib-file-samba, perl(Config::General), binutils, perl(URI), perl(Archive::Tar), perl(Error), perl(Net::LDAP), perl(DBI), perl(XML::LibXML), perl(DBD::Pg), samba-client, perl(Config::General), redhat-lsb

%description
Yaffas library in perl for yaffas products

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%post
# TODO: this is just fake! Remove me!
if [[ ! -e /etc/ldap.secret ]]; then
	touch /etc/ldap.secret
fi

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/lib/perl5
/opt/yaffas/lang


%changelog
