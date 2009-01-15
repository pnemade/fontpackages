# This template can be used with simple font releases
# (one font family in one upstream archive):
# — if you're unlucky enough upstream released several font families in a
#   single archive, use spectemplate-fonts-multi.spec
# – if upstream releases separate fonts in separate archives, do not try to
#   stuff them in a single spec/package, just package them separately
#
# Please remove the template comments when creating your own file;
# <FOO> must be replaced by something appropriate for your font.

%define fontname <FONTNAME>
%define fontconf <XX>-%{fontname}.conf

#define archivename %{name}-%{version}

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
Requires:       fontpackages-filesystem

%description


%prep
%setup -q


%build


%install
rm -fr %{buildroot}

install -m 0755 -d %{buildroot}%{_fontdir}
install -m 0644 -p *.ttf %{buildroot}%{_fontdir}

install -m 0755 -d %{buildroot}%{_fontconfig_templatedir} \
                   %{buildroot}%{_fontconfig_confdir}

install -m 0644 -p %{SOURCE1} \
        %{buildroot}%{_fontconfig_templatedir}/%{fontconf}
ln -s %{_fontconfig_templatedir}/%{fontconf} \
      %{buildroot}%{_fontconfig_confdir}/%{fontconf}


%clean
rm -fr %{buildroot}


%_font_pkg -f %{fontconf} *.ttf

%doc

%dir %{fontdir}


%changelog
