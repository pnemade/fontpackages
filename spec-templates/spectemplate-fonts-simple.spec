%global fontname <FONTNAME>
%global fontconf <①>-%{fontname}.conf

#global archivename %{name}-%{version} ②

Name:           %{fontname}-fonts
Version:        <③>
Release:        1%{?dist}
Summary:        

Group:          User Interface/X
License:        
URL:            
Source0:        
Source1:        %{name}-fontconfig.conf

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


%changelog


# Documentation
# (remove it from your final spec file, with the other comments)
#
#
# This template can be used with simple font releases
# (one font family ④ in one upstream archive):
# — if you're unlucky enough upstream released several font families in a
#   single archive, use spectemplate-fonts-multi.spec
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
# Do not trust font metadata versionning unless you've checked upstream does
# update versions on file changes. When in doubt use the timestamp of the most
# recent file as version. “1.0” versions especially are suspicious.
#
# ④
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
