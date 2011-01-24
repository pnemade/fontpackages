#! /usr/bin/env ruby
# -*- encoding: utf-8 mode: ruby -*-
# gen-defaultfonts-table.rb
# Copyright (C) 2010-2011 Red Hat, Inc.
#
# Authors:
#   Akira TAGOH  <tagoh@redhat.com>
#
# This library is free software: you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'rubygems'
require 'optparse'
begin
  require 'fontpackages/fontpackages'
rescue LoadError
  require File.join(File.dirname(__FILE__), '..', 'lib', 'fontpackages', 'fontpackages')
end
begin
  require 'fontpackages/yum'
rescue LoadError
  require File.join(File.dirname(__FILE__), '..', 'lib', 'fontpackages', 'yum')
end
begin
  require 'fontpackages/fontconfig'
rescue LoadError
  require File.join(File.dirname(__FILE__), '..', 'lib', 'fontpackages', 'fontconfig')
end

class FontInfo

  def initialize(fn, pkg, prio)
    @fontname = fn
    @package = pkg
    @priority = prio
  end # def initialize

  attr_reader :fontname, :package, :priority

end # class FontInfo

yum_opts = nil
rawhidever = nil
ignore = false
begin
  ARGV.options do |opt|
    opt.banner = sprintf("Usage: %s [options] <Fedora release>", File.basename(__FILE__))
    opt.on('--rawhidever=VERSION', 'tell the stupid tool what the version is supposed to be rawhide.') {|v| rawhidever = v}
    opt.on('--ignore-missing', "ignore an exception raised when the packages in comps isn't available") {|v| ignore = v}
    opt.parse!

    subargv = opt.order(ARGV)
    if subargv.length == 0 ||
        subargv[0] !~ /\A[0-9]+\Z/ then
      puts opt.help
      exit
    end
  end
  
  yum_opts = ARGV.yum_options << "--releasever=#{rawhidever == ARGV[0] ? "rawhide" : ARGV[0]}"
rescue => e
  p e
  exit
end

pkg2lang = {}
lang2pkg = {}

y = FontPackages::YumRepos.new(yum_opts)
fp = FontPackages::FontPackages.new("f#{ARGV[0]}")
langpkglist = {}
Comps::Root.new("f#{ARGV[0]}").groups(:langonly).each do |g|
  langpkglist[g.lang] = Comps::Group.new(g.name, g.lang, g.is_enabled?, g.is_visible?)
  langpkglist[g.lang].push(*g.packages(:default).map {|p| p.name =~ /-fonts\Z/ ? p : nil}.compact)
end
fontgrppkglist = Comps::Group.new('fonts', nil, true, true)
fontgrppkglist.push(*Comps::Root.new("f#{ARGV[0]}").groups.map{|g| g.name == 'fonts' || g.name == 'legacy-fonts' ? g : nil}.compact.map {|g| g.packages(:default).map {|p| p.name =~ /-fonts\Z/ ? p : nil}.compact}.flatten)

fp.fontpackages(:default).sort.each do |pkg|
  next if pkg2lang.include?(pkg.name)
  STDERR.printf("%s\n", pkg.name)
  pkg2lang[pkg.name] = fp.supported_languages(pkg)
  sans = []
  serif = []
  monospace = []
  other = []
  STDERR.printf("  Downloading rpm...\n")
  begin
    y.extract(pkg.name) do |rpm|
      rules_availability = false
      config_availability = false
      Dir.glob(File.join('etc', 'fonts', 'conf.d', '*')) do |f|
        STDERR.printf("  Checking a fontconfig file %s...\n", f)
        config_availability |= true
        fn = File.basename(f)
        tfn = File.join('usr', 'share', 'fontconfig', 'conf.avail', fn)
        priority = FontPackages::FontconfigPriority.new(tfn)
        fc = FontPackages::Fontconfig.new(tfn)
        generic_names_rule = Hpricot.XML("<fontconfig><alias><family>Name of your font</family><default><family>Generic like sans-serif, serif, monospace, fantasy or cursive</family></default></alias></fontconfig>")
        # postpone the conclusion of missing generic names rule
        # for packages that has multiple config files.
        if fc.include?(generic_names_rule) then
          rules_availability |= true
          if fc.has_alias?('sans-serif') then
            sans << FontInfo.new(fc.entity_of_alias('sans-serif'), pkg, priority)
          end
          if fc.has_alias?('serif') then
            serif << FontInfo.new(fc.entity_of_alias('serif'), pkg, priority)
          end
          if fc.has_alias?('monospace') then
            monospace << FontInfo.new(fc.entity_of_alias('monospace'), pkg, priority)
          end
        end
      end
      if !config_availability then
        STDERR.printf("W: %s: no fontconfig config files available\n", pkg.name)
      elsif !rules_availability then
        STDERR.printf("W: %s: no generic names rule available\n", pkg.name)
      end

      if sans.empty? && serif.empty? && monospace.empty? then
        other << pkg
      end
    end
  rescue RuntimeError => e
    if ignore then
      STDERR.printf("W: %s\n", e.message)
    else
      raise e
    end
  end
  pkg2lang[pkg.name].each do |l|
    lang2pkg[l] ||= {}
    lang2pkg[l][:sans] ||= []
    lang2pkg[l][:serif] ||= []
    lang2pkg[l][:monospace] ||= []
    lang2pkg[l][:other] ||= []
    STDERR.printf("  Aliases[%s]: ", l)
    unless sans.empty?
      lang2pkg[l][:sans].push(*sans)
      STDERR.printf("[sans] ")
    end
    unless serif.empty?
      lang2pkg[l][:serif].push(*serif)
      STDERR.printf("[serif] ")
    end
    unless monospace.empty?
      lang2pkg[l][:monospace].push(*monospace)
      STDERR.printf("[monospace] ")
    end
    unless other.empty?
      lang2pkg[l][:other].push(*other)
      STDERR.printf("[other] ")
    end
    STDERR.printf("\n")
  end
end
STDERR.printf("sorting out against the priority...\n")
lang2pkg.each do |l,v|
  v.each do |k, vv|
    if k == :other then
      lang2pkg[l][k] = vv.sort
    elsif vv.length > 0 then
      lang2pkg[l][k] = vv.sort{|x,y| x.priority <=> y.priority}
    end
  end
end

print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n"
print "<head><title>fonts list</title><style type=\"text/css\">\n"
print "table {\n"
print "  border-collapse: collapse;\n"
print "}\n"
print "table, th, td {\n"
print "  border: 1px solid black;\n"
print "}"
print "</style></head>\n"
print "<body>\n"
print "<div name='legend' style=\"font-size:10px;color:gray;\">Legend: <b>Bold</b>: default font, <i>Italic</i>: installed only when selecting the language support, <span style=\"color:gray;\">gray color</span>: affecting to the language if installed</div>"
print "<table><thead><tr><th>language</th><th>sans</th><th>serif</th><th>monospace</th><th>other</th></tr></thead>\n"
print "<tbody>"
proc = Proc.new do |a,lang|
  default = false
  lang_default = false
  (0..a.length-1).each do |i|
    printf(", ") if i > 0
    in_font = fontgrppkglist.has_package?(a[i].package)
    in_lang = !langpkglist[lang].nil? && langpkglist[lang].has_package?(a[i].package)
    printf("<b>") if (!default && (in_font || (!in_font && !in_lang))) || (!lang_default && in_lang)
    printf("<i>") if !in_font && in_lang
    printf("<span title='%s' style=\"%s\">%s</span>", a[i].package.name, !in_font && !in_lang ? "color: gray;" : "", a[i].fontname)
    printf("</i>") if !in_font && in_lang
    printf("</b>") if (!default && (in_font || (!in_font && !in_lang))) || (!lang_default && in_lang)
    if in_font then
      default = lang_default = true
    elsif in_lang then
      lang_default = true
    else
      default = true
    end
  end
end
lang2pkg.keys.sort.each do |l|
  print "<tr>"
  printf("<td>%s</td>", l)
  printf("<td>")
  proc.call(lang2pkg[l][:sans], l)
  printf("</td>\n<td>")
  proc.call(lang2pkg[l][:serif], l)
  printf("</td>\n<td>")
  proc.call(lang2pkg[l][:monospace], l)
  printf("</td>\n<td>")
  (0..lang2pkg[l][:other].length-1).each do |i|
    printf(", ") if i > 0
    package = lang2pkg[l][:other][i]
    in_font = fontgrppkglist.has_package?(package)
    in_lang = !langpkglist[l].nil? && langpkglist[l].has_package?(package)
    printf("<i>") if !in_font && in_lang
    printf("<span style=\"%s\">%s</span>", !in_font && !in_lang ? "color: gray;" : "", package.name)
    printf("</i>") if !in_font && in_lang
  end
  printf("</td>\n")
  print "</tr>\n"
end
print "</tbody></table>\n"
print "<div name=\"footer\" style=\"text-align:right;float:right;font-size:10px;color:gray;\">Generated by #{File.basename(__FILE__)} in <a href=\"http://git.fedorahosted.org/git/fontpackages.git\">fontpackages</a></div>\n"
print "</body>\n"
