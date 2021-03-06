#! /usr/bin/env ruby
# -*- encoding: utf-8 mode: ruby -*-
# comps.rb
# Copyright (C) 2009-2012 Red Hat, Inc.
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
require 'hpricot'
begin
  gem 'ruby-stemp'
  require 'stemp'
rescue LoadError
  require 'rbconfig'
  if RbConfig::CONFIG['MAJOR'].to_i <= 1 &&
      RbConfig::CONFIG['MINOR'].to_i <= 8 &&
      RbConfig::CONFIG['TEENY'].to_i < 7 then
    raise
  end
end
require 'tmpdir'


module Comps

=begin rdoc

== Comps::Package

=end

  class Package

    def initialize(name, type, requires)
      @name = name
      @type = type
      @requires = requires
    end # def initialize

    attr_reader :name

    def is_default?
      @type == "mandatory" || @type == "default"
    end # def is_default?

    def is_mandatory?
      @type == "mandatory"
    end # def is_mandatory?

    def <=>(b)
      @name <=> b.name
    end # def 

  end # class Package

=begin rdoc

== Comps::Group

=end

  class Group

    def initialize(name, lang, is_enabled, is_visible)
      @name = name
      @is_lang_support = !lang.nil? && !lang.empty?
      @lang = lang
      @is_enabled = is_enabled
      @is_visible = is_visible
      @packages = []
    end # def initialize

    attr_reader :name, :lang

    def is_language_support?
      @is_lang_support
    end # def is_language_support?

    def is_enabled?
      @is_enabled
    end # def is_enabled?

    def is_visible?
      @is_visible
    end # def is_visible?

    def push(*x)
      @packages.push(*x)
    end # def push

    alias :<< :push

    def packages(mode = :all)
      case mode
      when :all
        @packages
      when :default
        @packages.map do |pkg|
          pkg.is_default? ? pkg : nil
        end.compact
      else
        STDERR.printf("W: unknown query mode: %s\n", mode)
      end
    end # def packages

    def has_package?(package)
      @packages.map do |pkg|
        if package.kind_of?(Comps::Package) then
          pkg.name == package.name
        else
          pkg.name == package
        end
      end.include?(true)
    end # def has_package?

    def package(package)
      @package.each do |pkg|
        if package.kind_of?(Comps::Package) then
          return pkg if pkg.name == package.name
        else
          return pkg if pkg.name == package
        end
      end
      nil
    end # def package

  end # class Group

=begin rdoc

== Comps::Root

=end

  class Root

    def initialize(releaseprefix)
      unless defined? @@Releases2comps then
	@@Releases2comps = {}
        tmpdir = mktmpdir(File.join(Dir.tmpdir, "comps-XXXXXX"))
        cwd = Dir.pwd
        begin
          Dir.chdir(tmpdir)
          STDERR.printf("Checking out comps repo...\n")
          system("git clone git://git.fedorahosted.org/git/comps.git > /dev/null 2>&1")
          Dir.glob("comps/comps-*.xml.in") do |fn|
            doc = Hpricot.XML(File.open(fn).read)
            fn =~ /comps-(.*)\.xml\.in/
            @@Releases2comps[$1] = doc
          end
        ensure
          FileUtils.rm_rf(tmpdir) if !tmpdir.nil? && File.exist?(tmpdir)
          Dir.chdir(cwd)
        end
      end
      @doc = @@Releases2comps[releaseprefix]
      raise ArgumentError, sprintf("Unknown release %s. available comps is %s", releaseprefix, @@Releases2comps.keys.join(',')) if @doc.nil?
    end # def initialize

    def inspect
      sprintf("#<%s:0x%x>", self.class, self.object_id)
    end # def inspect

    def group(name)
      _groups.map do |g|
        g.name == name ? g : nil
      end.compact[0]
    end # def group

    def groups(mode = :all)
      case mode
      when :all
        _groups
      when :langonly
        _groups.map do |g|
          g.is_language_support? ? g : nil
        end.compact
      else
        STDERR.printf("W: unknown query mode: %s\n", mode)
      end
    end # def groups

    private

    def mktmpdir(path)
      retval = nil

      if defined?(STemp) then
        retval = STemp.mkdtemp(path)
      else
        retval = Dir.mktmpdir(path)
      end

      retval
    end # def mktmpdir

    def _groups
      retval = []
      @doc.search("group") do |element|
        id = element.search("id")
        if id.empty? then
          STDERR.printf("W: invalid entry: %s", element.pretty_print)
        else
          lang = element.search("langonly")
          default = element.search("default")
          visible = element.search("uservisible")
          retval << Comps::Group.new(id.inner_html, lang.inner_html, default.inner_html == "true", visible.inner_html == "true")
          list = element.search("packagereq")
          list.each do |pkg|
            retval[-1] << Comps::Package.new(pkg.inner_html, pkg[:type], pkg[:conditional])
          end
        end
      end
      retval
    end # def _groups

  end # class Root

end # module Comps
