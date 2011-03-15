Name:		yaffas-lib-config-crontab
Version:	1.10
Release:	1%{?dist}
Summary:	Read/Write Vixie compatible crontab(5) files
License:	GPL+ or Artistic
Group:		Applications/System
URL:		http://search.cpan.org/dist/Config-Crontab/
Source:		file://%{name}-%{version}.tar.gz
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:	noarch
BuildRequires:	perl(ExtUtils::MakeMaker)
Requires:	perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Config::Crontab provides an object-oriented interface to
Vixie-style crontab(5) files for Perl. A Config::Crontab 
object allows you to manipulate an ordered set of Event, 
Env, or Comment objects (also included with this package).

%build
make %{?_smp_mflags}


%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc debian/changelog
/opt/yaffas/lib/perl5

%changelog
