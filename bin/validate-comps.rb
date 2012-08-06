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

def validate_comps(yum, pkg, group)
  app_fonts = nil
  wrong_group = nil
  not_supported = nil
  prov = yum.provides(pkg).reject do |l|
    true unless l =~ /\Afont\(/
  end
  if prov.empty? then
    lst = yum.packagelist(pkg).reject do |l|
      true unless l.downcase =~ /.*\.(bdf|pcf)(?:\.gz)?\Z/
    end
    if lst.empty? then
      app_fonts = pkg
    else
      not_supported = pkg
    end
  else
    lst = yum.packagelist(pkg).reject do |l|
      true unless l.downcase =~ /.*\.(otf|ttf|ttc)\Z/
    end
    if lst.empty? then
      wrong_group = pkg if group != "legacy-fonts".to_sym
    else
      wrong_group = pkg if group != :fonts
    end
  end
  [wrong_group, app_fonts, not_supported]
end # def 

printf("Checking @fonts...\n")
pkgs_in_fonts.each do |pkg|
  wrong_font, apps_font, not_supported = validate_comps(yum, pkg.name, :fonts)
  printf("  %s: ->@legacy-fonts ?\n", pkg.name) unless wrong_font.nil?
  printf("  %s: no rpm metadata for fonts.\n", pkg.name) unless apps_font.nil?
end
printf("\nChecking @legacy-fonts...\n")
pkgs_in_legacy_fonts.each do |pkg|
  wrong_font, apps_font, not_supported = validate_comps(yum, pkg.name, "legacy-fonts".to_sym)
  printf("  %s: ->@fonts ?\n", pkg.name) unless wrong_font.nil?
  printf("  %s: no rpm metadata for fonts.\n", pkg.name) unless apps_font.nil?
end
