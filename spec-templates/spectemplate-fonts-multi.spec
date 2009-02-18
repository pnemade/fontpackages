%global fontname <FONTNAME>
%global fontconf <①>-%{fontname}

#global archivename %{name}-%{version} ②

%global common_desc \
<FONT COLLECTION DESCRIPTION: ③>


Name:           %{fontname}-fonts
Version:        <④>
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
Requires:       fontpackages-filesystem

%description common
%common_desc

This package consists of files used by other %{name} packages.

# Repeat for every font family ➅
%package -n %{fontname}-<FAMILY>-fonts
Summary:        
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


%changelog


# Documentation
# (remove it from your final spec file, with the other comments)
#
#
# This template can be used with complex multi-font releases
# (several font families ⑤ in one upstream archive):
# — if you intend to package a single font family, use
#   spectemplate-fonts-simple.spec
# – if upstream releases separate fonts in separate archives, do not try to
#   stuff them in a single srpm, just package them separately.
#
# <FOO> placeholders must be replaced by something appropriate for your font.
#
#
# ①
# Two-digit fontconfig priority number, see:
# /usr/share/fontconfig/templates/fontconfig-priorities.txt
#
# ②
# Optional
#
# ③
# This will be reused in every sub-package description.
# Please do not forget to complete it with subpackage-specific information.
#
# ④
# Do not trust font metadata versionning unless you've checked upstream does
# update versions on file changes. When in doubt use the timestamp of the most
# recent file as version. “1.0” versions especially are suspicious.
#
# ⑤
# — A font family corresponds to one entry in GUI font lists. For example,
#   DejaVu Sans, DejaVu Serif and DejaVu Sans Mono are three different font
#   families.
# — A font family is subdivided in faces or styles. DejaVu Sans Normal, DejaVu
#   Sans Bold, DejaVu Sans Condensed Italic are three faces of the DejaVu Sans
#   font family.
# — A font-metadata aware tool such as gnome-font-viewer or fontforge can be
#   used to check the font family name and the font face/style declared by a
#   font file.
# — For use in spec files, convert names to lowerscript and replace spaces
#   with “-”
