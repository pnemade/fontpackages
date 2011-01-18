# -*- encoding: utf-8 mode: ruby -*-
# fontpackages.rb
# Copyright (C) 2009-2011 Red Hat, Inc.
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
  require 'fontpackages/comps'
rescue LoadError
  require File.join(File.dirname(__FILE__), '..', 'fontpackages', 'comps')
end

module FontPackages

=begin rdoc

== FontPackages::FontPackages

=end

  class FontPackages

    def initialize(releaseprefix)
      @comps = Comps::Root.new(releaseprefix)
    end # def initialize

    def fontpackages(mode = :all)
      grps = @comps.groups(:langonly)
      grps << @comps.group("fonts")
      grps << @comps.group("legacy-fonts")
      grps.map do |grp|
        case mode
        when :all
          grp.packages
        when :default
          grp.packages(:default)
        else
          STDERR.printf("W: unknown query mode: %s\n", mode)
          []
        end.map do |pkg|
          pkg.name =~ /-fonts\Z/ ? pkg : nil
        end.compact
      end.flatten
    end # def fontpackages

    def supported_languages(package)
      retval = []

      @comps.groups.each do |grp|
        if grp.has_package?(package) then
          if grp.name !~ /fonts/ && (grp.lang.nil? || grp.lang.empty?) then
            # assuming it may be "en"
            retval << "en"
          else
            retval << grp.lang if !grp.lang.nil? && !grp.lang.empty?
          end
        end
      end

      retval
    end # def supported_languages

    def is_lgc_font?(package)
      lang = supported_languages(package)
      ll = []
      # Latin-1
      ll[1] = ['af', 'sq', 'br', 'ca', 'da', 'en', 'en_GB', 'gl', 'de', 'is', 'ga', 'it', 'ku', 'la', 'lb', 'nb', 'oc', 'pt_BR', 'pt', 'es', 'sw', 'sv', 'wa', 'eu'] # XXX: Faroese, Leonese, Rhaeto-Romanic, Scottish Gaelic
      # Latin-2
      ll[2] = ['bs', 'hr', 'cs', 'de', 'hu', 'pl', 'ro', 'sr', 'sk', 'sl', 'hsb'] # XXX: Lower Sorbian
      # Latin-3
      ll[3] = ['tr', 'mt', 'eo']
      # Latin-4
      ll[4] = ['et', 'lv', 'lt'] # XXX: Greenlandic, Sami
      # Latin/Cyrillic
      ll[5] = ['bg', 'be', 'ru', 'sr', 'mk']
      # Latin/Arabic
      #ll[6] = ['ar']
      # Latin/Greek
      ll[7] = ['el', 'ka']
      # Latin/Hebrew
      #ll[8] = ['he']
      # Latin-5
      ll[9] = ['tr']
      # Latin-6
      ll[10] = ['is', 'nb', 'da', 'sv'] # XXX: Faroese
      # Latin/Thai
      #ll[11] = ['th']
      # Latin/Devanagari
      # ll12: for Devanagari
      # Latin-7
      #ll[13] = [] # XXX: Western Baltic, Eastern Baltic
      # Latin-8
      ll[14] = ['gd', 'cy', 'br']
      # Latin-9
      ll[15] = ['af', 'sq', 'br', 'ca', 'da', 'nl', 'en', 'en_GB', 'et', 'fi', 'fr', 'gl', 'de', 'is', 'ga', 'it', 'ku', 'la', 'lb', 'ms', 'nb', 'oc', 'pt_BR', 'pt', 'es', 'sw', 'tl', 'wa'] # XXX: Faroese, Rhaeto-Romanic, Scottish Gaelic, Scots
      # Latin-10
      ll[16] = ['sq', 'hr', 'hu', 'pl', 'ro', 'sl', 'fr', 'de', 'it', 'ga']

      retval = false
      ll.flatten.compact.sort.uniq.each do |l|
        retval ||= lang.include?(l)
        break if retval
      end
      retval
    end # def is_lgc_font?

    def is_cijk_font?(package)
      lang = supported_languages(package)
      indic = ['as', 'bn', 'hne', 'gu', 'hi', 'kn', 'ks', 'kok', 'mai', 'ml', 'mr', 'ne', 'or', 'pa', 'sa', 'sd', 'si', 'ta', 'te']
      cjk = ['zh', 'ja', 'ko']
      retval = false
      (cjk + indic).each do |ll|
        retval ||= lang.include?(ll)
        break if retval
      end
      retval
    end # def is_cijk_font?

  end # class FontPackages

end # module FontPackages
