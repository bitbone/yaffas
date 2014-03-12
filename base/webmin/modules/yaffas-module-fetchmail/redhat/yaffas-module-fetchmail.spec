Name:		yaffas-module-fetchmail
Version:	1.0.0
Release:	1%{?dist}
Summary:	Webmin fetchmail module
Group:		Applications/System
License:	AGPLv3
URL:		http://www.yaffas.org
Source0:	file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:	yaffas-install-lib, fetchmail, yaffas-core, yaffas-lib
AutoReqProv: no

%description
Webmin fetchmail module

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%post
set -e
if [ $1 -eq 1 ]; then
	# set selinux context
	if selinuxenabled; then
		/usr/bin/chcon -u system_u -r object_r -t initrc_exec_t /opt/yaffas/etc/init.d/fetchmail
	fi

	if [ ! -e %{_initrddir}/fetchmail ]; then
		ln -s /opt/yaffas/etc/init.d/fetchmail %{_initrddir}/fetchmail
	fi

	# fetchmail runs as user fetchmail
	groupadd -r fetchmail
	useradd -r -m -g fetchmail -s /bin/false -c "Fetchmail" fetchmail
	touch /etc/fetchmailrc
	chown fetchmail:fetchmail /etc/fetchmailrc
	chmod 600 /etc/fetchmailrc

	/sbin/chkconfig --add fetchmail
	/sbin/chkconfig fetchmail on
fi

source /opt/yaffas/lib/bbinstall-lib.sh
MODULE=fetchmail
add_webmin_acl $MODULE

%postun
if [ "$1" = "0" ]; then
	source /opt/yaffas/lib/bbinstall-lib.sh
	MODULE=fetchmail
	del_webmin_acl $MODULE
fi

%files
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}
/opt/yaffas/webmin/fetchmail
/opt/yaffas/etc/init.d/fetchmail
/opt/yaffas/etc/webmin/fetchmail/config


%changelog
