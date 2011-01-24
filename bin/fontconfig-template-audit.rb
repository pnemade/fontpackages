#! /usr/bin/env ruby
# fontconfig-template-audit.rb
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

config = {}

begin
  ARGV.options do |opt|
    opt.banner = sprintf("Usage: %s [options] <Fedora release|package.rpm>", File.basename(__FILE__))
    opt.on('--rawhidever=VERSION', 'tell the stupid tool what the version is supposed to be rawhide.') {|v| config[:rawhidever] = v}
    opt.on('--ignore-error', 'Do not raise exceptions and continue the process.') {|v| config[:ignore_error] = v}
    opt.on('--target=default|all', 'specify which packages sets are targeted for audit') do |v|
      if v.downcase == 'all' || v.downcase == 'default' then
        config[:target] = v.downcase.to_sym
      else
        raise RuntimeError, sprintf("Unknown target: %s", v)
      end
    end

    opt.parse!

    subargv = opt.order(ARGV)
    if subargv.length == 0 ||
        (subargv[0] !~ /\A[0-9]+\Z/ &&
         subargv[0] !~ /\.rpm\Z/) then
      puts opt.help
      exit
    end
  end

  config[:yum] = ARGV.yum_options
rescue => e
  p e
  exit
end

config[:target] ||= :default

# XXX: hardcode the type of rules
#      since the templates contains
#      multiple rules for convenience.
templates = {
  "Font substitution"=>"<alias binding=\"same\"><family>Name of the font to substitute for</family><accept><family>Name of your font</family></accept></alias>",
  "Generic names"=>"<alias><family>Name of your font</family><default><family>Generic like sans-serif, serif, monospace, fantasy or cursive</family></default></alias>",
  "Simple priority lists"=>"<alias><family>Generic like sans-serif, serif, monospace, fantasy or cursive</family><prefer><family>Name of your font</family></prefer></alias>",
  "Locale-specific overrides"=>"<match><test name=\"lang\"><string>Locale code</string></test><test name=\"family\"><string>Generic like sans-serif, serif, monospace, fantasy or cursive</string></test><edit name=\"family\" mode=\"prepend\"><string>Name of your font</string></edit></match>",
  "Auto-scaling problem fonts"=>"<match target=\"font\"><test name=\"family\" mode=\"eq\"><string>Name of your font</string></test><edit name=\"matrix\" mode=\"assign\"><times><name>matrix</name><matrix><double>Factor like 1.2</double><double>0</double><double>0</double><double>Factor like 1.2</double></matrix></times></edit></match>"
}

y = nil
fp = nil
if ARGV[0] =~ /\.rpm\Z/ then
  y = FontPackages::RPMFile.new(ARGV[0])
  class DummyFontPackages

    def initialize(rpmfile)
      @rpmfile = rpmfile
    end # def initialize

    def fontpackages(n)
      [Comps::Package.new(File.basename(@rpmfile.name), nil, nil)]
    end # def fontpackages

  end # class DummyFontPackages
  fp = DummyFontPackages.new(y)
else
  config[:yum] << "--releasever=#{config[:rawhidever] == ARGV[0] ? "rawhide" : ARGV[0]}"
  y = FontPackages::YumRepos.new(config[:yum])
  y.ignore_error = config[:ignore_error]
  fp = FontPackages::FontPackages.new("f#{ARGV[0]}")
end
result = {}
begin
  fp.fontpackages(config[:target]).sort.each do |pkg|
    next if result.include?(pkg.name)
    result[pkg.name] = {}
    STDERR.printf("Checking %s...\n", pkg.name)
    y.extract(pkg.name) do |rpm|
      Dir.glob(File.join('etc', 'fonts', 'conf.d', '*')) do |f|
        STDERR.printf("  Checking %s...\n", f)
        fn = File.basename(f)
        tfn = File.join('usr', 'share', 'fontconfig', 'conf.avail', fn)
        fc = FontPackages::Fontconfig.new(tfn)

        a = fc.to_a
        a.normalize = true
        size = a.length

        templates.each do |key, val|
          xml = Hpricot.XML("<fontconfig>#{val}</fontconfig>")
          a -= xml if fc.include?(xml, :normalize=>true)
          if a.length != size then
            result[pkg.name][fn] ||= {}
            result[pkg.name][fn][:authorized] ||= []
            result[pkg.name][fn][:authorized] << key
            size = a.length
          end
        end
        unless a.empty? then
          STDERR.printf("W: %s: %s may contains the non-authorized rule\n", pkg.name, fn)
          result[pkg.name][fn] ||= {}
          result[pkg.name][fn][:nonauthorized] ||= []
          result[pkg.name][fn][:nonauthorized] << a
        end
      end
      if result[pkg.name].empty? then
	availconf = Dir.glob(File.join('usr', 'share', 'fontconfig', 'conf.avail', '*'))
	if availconf.empty? then
          STDERR.printf("E: %s: no fontconfig config files provided\n", pkg.name)
        else
          availconf.each do |f|
            fn = File.basename(f)
            result[pkg.name][fn] ||= {}
            result[pkg.name][fn][:not_enabled] ||= []
            result[pkg.name][fn][:not_enabled] << []
          end
        end
      end
    end
  end
ensure
  print "\n"
  result.keys.sort.each do |pkg|
    printf("* %s:\n", pkg)
    v = result[pkg]
    printf("  * E: no fontconfig files provided\n") if v.empty?
    v.keys.sort.each do |fn|
      v[fn].each do |type, val|
        printf("  * %s:\n", type)
        printf("    * %s: %s\n", fn, val.join(', '))
      end
    end
  end
end
