Summary:    Module for configuration of mail security options
Name:       yaffas-module-security
Version:    1.0.0
Release:    1
License:    AGPLv3
Url:        http://www.yaffas.org
Group:      Applications/System
Source:     file://%{name}-%{version}.tar.gz
BuildArch:  noarch
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:   yaffas-install-lib, yaffas-core, perl-Net-DNS, amavisd-new, clamav, clamd, spamassassin, policyd-weight
AutoReqProv: no

%description
Module for configuration of mail security options

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
set -e
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="security"
add_webmin_acl $MODULE
add_license $MODULE ""

#[[ -e /etc/default/spamassassin ]] && sed -e 's/^ENABLED=0/ENABLED=1/' -i /etc/default/spamassassin

%{__mv} -f /etc/policyd-weight.conf /etc/policyd-weight.conf.yaffassave
%{__cp} -f -a /opt/yaffas/share/doc/example/etc/policyd-weight.conf /etc
%{__mv} -f /etc/amavisd.conf /etc/amavisd.conf.yaffassave
%{__cp} -f -a /opt/yaffas/share/doc/example/etc/amavisd-redhat.conf /etc/amavisd.conf
mkdir -p /etc/amavis/conf.d/
%{__cp} -f -a /opt/yaffas/share/doc/example/etc/amavis/conf.d/60-yaffas /etc/amavis/conf.d/60-yaffas

if ! id clam | grep -q "amavis"; then
    usermod -a -G amavis clam
fi

if ! grep -q "amavis" /etc/postfix/master.cf; then
    cat /opt/yaffas/share/doc/example/etc/amavis-master.cf >> /etc/postfix/master.cf
fi

%postun
%{__mv} -f /etc/policyd-weight.conf.yaffassave /etc/policyd-weight.conf

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/security
/opt/yaffas/lib/perl5/Yaffas/Module/Security.pm
/opt/yaffas/config/channels.cf
/opt/yaffas/config/channels.keys
/opt/yaffas/config/whitelist-amavis
/opt/yaffas/config/whitelist-postfix
/opt/yaffas/share/doc/example/etc/amavis/conf.d/60-yaffas
/opt/yaffas/share/doc/example/etc/policyd-weight.conf
/opt/yaffas/share/doc/example/etc/amavis-master.cf
/opt/yaffas/share/doc/example/etc/amavisd-redhat.conf

%changelog

