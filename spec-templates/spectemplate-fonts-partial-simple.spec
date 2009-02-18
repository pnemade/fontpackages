%global fontconf <①>-%{name}-<FAMILY>.conf

# …

Source1:        %{name}-<FAMILY>-fontconfig.conf
BuildRoot:      

BuildRequires:  fontpackages-devel

# …

%package <FAMILY>-fonts
Summary:        
Group:          User Interface/X
BuildArch:      noarch
Requires:       fontpackages-filesystem

%description <FAMILY>-fonts

<FAMILY DESCRIPTION>

%_font_pkg -n <FAMILY> -f %{fontconf} <NAME>*.ttf

%doc <FONT DOCUMENTATION>

# …

%install
rm -fr %{buildroot}

# …

install -m 0755 -d %{buildroot}%{_fontdir}
install -m 0644 -p *.ttf %{buildroot}%{_fontdir}

install -m 0755 -d %{buildroot}%{_fontconfig_templatedir} \
                   %{buildroot}%{_fontconfig_confdir}

install -m 0644 -p %{SOURCE1} \
        %{buildroot}%{_fontconfig_templatedir}/%{fontconf}
ln -s %{_fontconfig_templatedir}/%{fontconf} \
      %{buildroot}%{_fontconfig_confdir}/%{fontconf}

# …


# Documentation
# (remove it from your final spec file, with the other comments)
#
#
# This is a partial template. It shows how one may create a single font
# subpackage in a non-font package. Since the non-fonts part of those
# packages may vary a lot only spec extracts are documented there. Also:
# — packaging fonts in separate dedicated packages is usually lower
#   maintenance than using this kind of subpackaging trick.
# — if your srpm contains more than one font familiy ②, look at
#   spectemplate-fonts-partial-multi.spec
#

#
# ①
# Two-digit fontconfig priority number, see:
# /usr/share/fontconfig/templates/fontconfig-priorities.txt
#
#
# ②
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
