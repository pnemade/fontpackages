# This template can be used with complex multi-font releases
# (several font families in one upstream archive):
# — if you intend to package a single font family, use
#   spectemplate-fonts-simple.spec
# – if upstream releases separate fonts in separate archives, do not try to
#   stuff them in a single spec/package, just package them separately
#
# Please remove the template comments when creating your own file;
# <FOO> must be replaced by something appropriate for your font.

%define fontname <FONTNAME>
%define fontconf <XX>-%{fontname}

#define archivename %{name}-%{version}

# This will be reused in every sub-package description
# Please do not forget to complete it with subpackage-specific information
%define common_desc \
<FONT COLLECTION DESCRIPTION>


Name:           %{fontname}-fonts
# Do not trust font metadata versionning unless you've checked upstream does
# update versions on file changes. When in doubt use the timestamp of the most
# recent file as version.
Version:        
Release:        1%{?dist}
Summary:        

Group:          User Interface/X
License:        
URL:            
Source0:        
Source1:        %{name}-fontconfig.conf
BuildRoot:      %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

BuildArch:      noarch
BuildRequires:  fontpackages-devel

%description
%common_desc


%package common
Summary:        Common files of <NAME>
Group:          User Interface/X
Requires:       fontpackages-filesystem

%description common
%common_desc

This package consists of files used by other %{name} packages.

# Repeat for every font family
%package -n %{fontname}-<FAMILY>-fonts
Summary:        
Group:          User Interface/X
Requires:       %{name}-common = %{version}-%{release}

%description -n %{fontname}-<FAMILY>-fonts
%common_desc

<FAMILY DESCRIPTION>

%_font_pkg -n <FAMILY> -f %{fontconf}-<FAMILY>.conf <NAME>*.ttf


%prep
%setup -q


%build


%install
rm -fr %{buildroot}

install -m 0755 -d %{buildroot}%{_fontdir}
install -m 0644 -p *.ttf %{buildroot}%{_fontdir}

install -m 0755 -d %{buildroot}%{_fontconfig_templatedir} \
                   %{buildroot}%{_fontconfig_confdir}

# Repeat for every font family
install -m 0644 -p %{SOURCEX} \
        %{buildroot}%{_fontconfig_templatedir}/%{fontconf}-<FAMILYX>.conf

for fconf in %{fontconf}-<FAMILYX>.conf \
             %{fontconf}-<FAMILYY>.conf \
             %{fontconf}-<FAMILYZ>.conf ; do
  ln -s %{_fontconfig_templatedir}/$fconf \
        %{buildroot}%{_fontconfig_confdir}/$fconf
done


%clean
rm -fr %{buildroot}


%files common
%defattr(0644,root,root,0755)
%doc 

%dir %{_fontdir}


%changelog
