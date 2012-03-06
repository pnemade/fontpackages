# yum.rb
# Copyright (C) 2010-2012 Red Hat, Inc.
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
begin
  gem 'ruby-stemp'
  require 'stemp'
rescue LoadError
  require 'rbconfig'
  if Config::CONFIG['MAJOR'].to_i <= 1 &&
      Config::CONFIG['MINOR'].to_i <= 8 &&
      Config::CONFIG['TEENY'].to_i < 7 then
    raise
  end
end
require 'fileutils'
require 'optparse'
require 'shellwords'
require 'tmpdir'
begin
  require 'fontpackages/compat'
rescue LoadError
  require File.join(File.dirname(__FILE__), '..', 'fontpackages', 'compat')
end


def mktmpdir(path)
  retval = nil

  if defined?(STemp) then
    retval = STemp.mkdtemp(path)
  else
    retval = Dir.mktmpdir(path)
  end

  retval
end # def mktmpdir

class OptionParser

  module Arguable

    alias :orig_options :options

    def options
      @yum_config ||= []
      orig_options do |opt|
        opt.on('-C', '--cache', '[YUM] run from cache only') {|v| @yum_config << '-C'}
        opt.on('--enablerepo=REPO', '[YUM] enable one or more repositories (wildcards allowed)') {|v| @yum_config << build_yumopt(:enablerepo, v)}
        opt.on('--disablerepo=REPO', '[YUM] disable one or more repositories (wildcards allowed)') {|v| @yum_config << build_yumopt(:disablerepo, v)}

        yield opt
      end
    end # def options

    def yum_options
      @yum_config
    end # def yum_options

    private

    def build_yumopt(key, val)
      sprintf("--%s=%s", key, val.shellescape)
    end

  end # module Arguable

end # class OptionParser

module FontPackages

  class YumRepos

    def initialize(yumopts)
      @yumopts = yumopts
      @query_format = ""
      @ignore_error = false
    end # def initialize

    attr_accessor :query_format, :ignore_error

    def query(name, &block)
      repoquery([yum_options, "-q", @query_format.empty? ? "" : sprintf("--qf=%s", @query_format), name], &block)
    end # def query

    def packagelist(name, &block)
      repoquery([yum_options, "-l", name], &block)
    end # def packagelist

    def download(name)
      tmpdir = nil
      nvra = nil
      begin
        old_qf = query_format
        self.query_format = "%{name}-%{version}-%{release}.%{arch}"
        query(name) do |ret|
          nvra = ret
          break
        end
      ensure
        self.query_format = old_qf
      end
      if nvra.nil? then
        e = RuntimeError.new(sprintf("No such packages: %s", name))
        if ignore_error then
          STDERR.printf("E: %s\n", e.message)
          return
        else
          raise e
        end
      end
      if block_given? then
        tmpdir = mktmpdir(File.join(Dir.tmpdir, sprintf("%sXXXXXXXX", name)))
      end
      cwd = Dir.pwd
      begin
        Dir.chdir(tmpdir) unless tmpdir.nil?
        cmd = sprintf("yumdownloader %s %s > /dev/null 2>&1", yum_options, nvra)
        STDERR.printf("D: %s\n", cmd) if $DEBUG
        system(cmd)
        rpm = sprintf("%s.rpm", nvra)
        unless File.exist?(rpm) then
          e = RuntimeError.new(sprintf("Unable to download rpm: %s", nvra))
          if ignore_error then
            STDERR.printf("E: %s\n", e.message)
          else
            raise e
          end
        end
        yield self, RPMFile.new(rpm)
      ensure
        FileUtils.rm_rf(tmpdir) unless tmpdir.nil?
        Dir.chdir(cwd)
      end
    end # def download

    def extract(name, &block)
      download(name) do |x, rpm|
        rpm.extract(&block)
      end
    end # def extract

    private

    def yum_options
      if @yumopts.kind_of?(Array) then
        @yumopts.join(' ')
      elsif !@yumopts.nil? then
	@yumopts
      else
        ""
      end
    end # def yum_options

    def repoquery(opts)
      cmd = sprintf("repoquery %s 2> /dev/null", opts.join(' '))
      STDERR.printf("D: %s\n", cmd) if $DEBUG
      IO.popen(cmd) do |f|
        until f.eof? do
          s = f.gets
          yield s.chomp unless s.nil?
        end
      end
    end # def repoquery

  end # class YumRepos

  class RPMFile

    def initialize(filename)
      @name = filename
    end # def initialize

    attr_reader :name

    def extract(nop = nil)
      tmpdir = mktmpdir(File.join(Dir.tmpdir, sprintf("%sXXXXXXXX", File.basename(name))))
      cwd = Dir.pwd
      begin
        Dir.chdir(tmpdir) unless tmpdir.nil?
        rpm = @name
        if File.dirname(@name) == '.' then
          rpm = File.join(cwd, @name)
        end
        cmd = sprintf("rpm2cpio %s | cpio -id > /dev/null 2>&1", rpm)
        STDERR.printf("D: %s\n", cmd) if $DEBUG
        system(cmd)
        yield self
      ensure
        FileUtils.rm_rf(tmpdir) unless tmpdir.nil?
        Dir.chdir(cwd)
      end
    end # def extract

    def <=>(x)
      x <=> @name
    end # def <=>

    def ==(x)
      x == @name
    end # def ==

    def to_s
      @name
    end # def to_s

  end # class RPMFile

end # module FontPackages
