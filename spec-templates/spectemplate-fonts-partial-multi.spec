%global fontconf <①>-%{name}

# …

%global common_font_desc \
<FONT COLLECTION DESCRIPTION: ②>

Source1:        %{name}-<FAMILY>-fontconfig.conf
# …

BuildRequires:  fontpackages-devel

%description
%common_font_desc


%package fonts-common
Summary:        Common files of <NAME>
Group:          User Interface/X
BuildArch:      noarch
Requires:       fontpackages-filesystem

%description fonts-common
%common_font_desc

This package consists of files used by other %{name} font packages.


# Repeat for every font family ③
%package <FAMILY>-fonts
Summary:        
Group:          User Interface/X
BuildArch:      noarch
Requires:       %{name}-fonts-common = %{version}-%{release}

%description -n %{fontname}-<FAMILY>-fonts
%common_font_desc

<FAMILY DESCRIPTION>

%_font_pkg -n <FAMILY> -f %{fontconf}-<FAMILY>.conf <NAME>*.ttf

%doc <FONT DOCUMENTATION>

# …

%install
rm -fr %{buildroot}

# …

install -m 0755 -d %{buildroot}%{_fontdir}
install -m 0644 -p *.ttf %{buildroot}%{_fontdir}

install -m 0755 -d %{buildroot}%{_fontconfig_templatedir} \
                   %{buildroot}%{_fontconfig_confdir}

# Repeat for every font family ③
install -m 0644 -p %{SOURCEX} \
        %{buildroot}%{_fontconfig_templatedir}/%{fontconf}-<FAMILYX>.conf

for fconf in %{fontconf}-<FAMILYX>.conf \
             %{fontconf}-<FAMILYY>.conf \
             %{fontconf}-<FAMILYZ>.conf ; do
  ln -s %{_fontconfig_templatedir}/$fconf \
        %{buildroot}%{_fontconfig_confdir}/$fconf
done

# …

%files common
%defattr(0644,root,root,0755)
%doc <FONT DOCUMENTATION>

# …

# Documentation
# (remove it from your final spec file, with the other comments)
#
#
# This is a partial template. It shows how one may create several font
# subpackages in a non-font package. Since the non-fonts part of those
# packages may vary a lot only spec extracts are documented there. Also:
# — packaging fonts in separate dedicated packages is usually lower
#   maintenance than using this kind of subpackaging trick.
# — if your srpm contains only one font familiy ③, look at
#   spectemplate-fonts-partial-simple.spec
#
# <FOO> placeholders must be replaced by something appropriate for your font.
#
#
# ①
# Two-digit fontconfig priority number, see:
# /usr/share/fontconfig/templates/fontconfig-priorities.txt
#
# ②
# This will be reused in every font package description.
# Please do not forget to complete it with subpackage-specific information.
#
# ③
# A font family corresponds to one entry in GUI font lists. For example,
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
