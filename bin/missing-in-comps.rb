#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'rubygems'
require 'optparse'

begin
  require 'fontpackages/comps'
rescue LoadError
  require File.join(File.dirname(__FILE__), '..', 'lib', 'fontpackages', 'comps')
end
begin
  require 'fontpackages/yum'
rescue LoadError
  require File.join(File.dirname(__FILE__), '..', 'lib', 'fontpackages', 'yum')
end

yum_opts = nil
rawhidever = nil

begin
  ARGV.options do |opt|
    opt.banner = sprintf("Usage: %s [options] <Fedora release>", File.basename(__FILE__))
    opt.on('--rawhidever=VERSION', 'tell the stupid tool what the version is supposed to be rawhide.') {|v| rawhidever = v}
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

comps = Comps::Root.new("f#{ARGV[0]}")
pkgs_in_fonts = comps.group("fonts").packages
pkgs_in_legacy_fonts = comps.group("legacy-fonts").packages
yum = FontPackages::YumRepos.new(yum_opts)
yum.query_format = "%{name}"
pkgs_in_repos = yum.query("*-fonts")

missing_in_repos = []

pkgs_in_fonts.each do |pkg|
  unless pkgs_in_repos.include?(pkg.name) then
    missing_in_repos << pkg.name
  else
    pkgs_in_repos.delete(pkg.name)
  end
end
pkgs_in_legacy_fonts.each do |pkg|
  unless pkgs_in_repos.include?(pkg.name) then
    missing_in_repos << pkg.name
  else
    pkgs_in_repos.delete(pkg.name)
  end
end

app_fonts = []
missing_in_comps = []

pkgs_in_repos.each do |x|
  prov = yum.provides(x).reject do |l|
    true unless l =~ /\Afont\(/
  end
  if prov.empty? then
    app_fonts << x
  else
    if prov.map{|x| x !~ /\Afont\(:lang=.*\)/ ? nil : x}.compact.empty? then
      lst = yum.packagelist(x).reject do |l|
        true unless l.downcase =~ /.*[ot]tf\Z/
      end
      if lst.empty? then
        missing_in_comps << [x, "legacy-fonts".to_sym]
      else
        missing_in_comps << [x, :fonts, :maybe_broken]
      end
    else
      lst = yum.packagelist(x).reject do |l|
        true unless l.downcase =~ /.*[ot]tf\Z/
      end
      if lst.empty? then
        missing_in_comps << [x, "legacy-fonts".to_sym]
      else
        missing_in_comps << [x, :fonts]
      end
    end
  end
end

print "missing in comps:\n"
missing_in_comps.each do |x, y, z|
  printf("%s (@%s) %s\n", x, y, z)
end
print "\nmaybe application specific fonts?:\n"
app_fonts.each do |x|
  printf("%s\n", x)
end
