Name:		yaffas-ckeditor
Version:	4.0
Release:	1%{?dist}
Summary:	CKeditor Library
Group:		Application/System
License:	AGPLv3
BuildArch:	noarch
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:	yaffas-core

%description
CKEditor Library

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%files
/opt/yaffas/webmin/ckeditor
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}

%changelog
