# fontconfig.rb
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
gem 'hpricot'
require 'hpricot'


module FontPackages

=begin rdoc

== FontPackages::FontconfigElement

=end

  class FontconfigElement

    def initialize(elem)
      @element = elem
      @ignore_attributes = false
      @ignore_text = true
    end # def initialize

    attr_accessor :ignore_attributes, :ignore_text

    def ==(xelem)
      return false if @element.name != xelem.name
      if @element.kind_of?(Hpricot::Text) ||
          xelem.kind_of?(Hpricot::Text) then
        return @element.content == xelem.content if !@ignore_text
        return @element.kind_of?(Hpricot::Text) && xelem.element.kind_of?(Hpricot::Text)
      else
        return false if !@ignore_attributes && @element.attributes.to_hash != xelem.attributes.to_hash
      end
      if @ignore_text then
        xchildren = @element.children.reject {|x| x.kind_of?(Hpricot::Text)}
        ychildren = xelem.children.reject {|x| x.kind_of?(Hpricot::Text)}
      else
        xchildren = @element.children
        ychildren = xelem.children
      end
      prev = nil
      xchildren.reject! do |x|
        if !prev.nil? && x.name == prev.name &&
            x.name =~ /\Afamily\Z/ then
          true
        else
          prev = x
          false
        end
      end
      prev = nil
      ychildren.reject! do |y|
        if !prev.nil? && y.name == prev.name &&
            y.name =~ /\Afamily\Z/ then
          true
        else
          prev = y
          false
        end
      end
      return false if xchildren.length != ychildren.length
      return true if xchildren.empty? && ychildren.empty?
      xchildren.sort! do |x, y|
        z = x.name <=> y.name
        z = x.attributes.to_hash.keys.sort <=> y.attributes.to_hash.keys.sort if z == 0
        z = x.attributes.to_hash.values.sort <=> y.attributes.to_hash.values.sort if z == 0
        z
      end
      ychildren.sort! do |x, y|
        z = x.name <=> y.name
        z = x.attributes.to_hash.keys.sort <=> y.attributes.to_hash.keys.sort if z == 0
        z = x.attributes.to_hash.values.sort <=> y.attributes.to_hash.values.sort if z == 0
        z
      end
      xchildren.map! do |x|
        if x.kind_of?(::FontPackages::FontconfigElement) then
          x
        else
          ::FontPackages::FontconfigElement.new(x)
        end
      end
      ychildren.map! do |y|
        if y.kind_of?(::FontPackages::FontconfigElement) then
          y
        else
          ::FontPackages::FontconfigElement.new(y)
        end
      end
      ret = (0..(xchildren.length - 1)).reject do |i|
        xchildren[i].ignore_attributes = ychildren[i].ignore_attributes = @ignore_attributes
        xchildren[i].ignore_text = ychildren[i].ignore_text = @ignore_text
        xchildren[i] == ychildren[i]
      end
      ret.empty?
    end # def =

    def method_missing(*args)
      @element.__send__(*args)
    end # def method_missing

    protected

    def element
      @element
    end # def element

  end # class FontconfigElement

=begin rdoc

== FontPackages::FontconfigElements

=end

  class FontconfigElements < Array

    def initialize(*args)
      @ignore_text = true
      @ignore_attributes = false
      @normalize = false
      super
    end # def initialize

    attr_accessor :ignore_text, :ignore_attributes, :normalize

    def -(reference)
      hresult = nil
      ref = reference
      if @normalize then
	hresult = Hash[self.map do |x|
                         _xml_ = Hpricot.XML(x.to_s)
                         _xml_ = ::FontPackages::Fontconfig.normalize(_xml_/"*")
                         [_xml_[0],x]
                       end]
        ref = Hpricot.XML(ref.to_s)
        ret = ::FontPackages::Fontconfig.normalize(ref/"*")
      else
        hresult = Hash[self.map{|x| [x,x]}]
      end

      (ref/"fontconfig/*").each do |xelement|
        next if @ignore_text && xelement.kind_of?(Hpricot::Text)
        next if xelement.kind_of?(Hpricot::Comment)
        x = ::FontPackages::FontconfigElement.new(xelement)
        x.ignore_attributes = @ignore_attributes
        x.ignore_text = @ignore_text
        path = xelement.xpath.sub(/\A\//, '').sub(/\[\d+\]\Z/, '')
        hresult.reject! do |item, orig|
          y = ::FontPackages::FontconfigElement.new(item)
          y.ignore_attributes = @ignore_attributes
          y.ignore_text = @ignore_text
          x == y
        end
      end
      ret = ::FontPackages::FontconfigElements.new(hresult.values)
      ret.normalize = @normalize
      ret
    end # def -

  end # class FontconfigElements

=begin rdoc

== FontPackages::FontconfigPriority

=end

  class FontconfigPriority

    def initialize(file)
      @priorities = []
      f = File.basename(file)

      while f =~ /\A(\d+).*/ do
        @priorities << $1
        f.sub!(/\A(\d+)/, '')
        f.sub!(/\A-/, '')
      end
    end # def initialize

    attr_reader :priorities

    def <=>(o)
      l = o.priorities.length
      (0..l-1).each do |n|
        x = @priorities[n].to_i
        y = o.priorities[n].to_i
        return 0 if x.nil? && y.nil? # unlikely
        return 1 if x.nil?
        return -1 if y.nil?
        r = x <=> y
        return r if r != 0
      end
      0
    end # def <=>

  end # class FontconfigPriority

=begin rdoc

== FontPackages::Fontconfig

=end

  class Fontconfig

    class << self

      def normalize(xml, ignore_text = true)
        old = @ignore_text
        @ignore_text = ignore_text
	ret = _normalize_elements(xml)
        @ignore_text = old

        ret
      end # def normalize

      private

      def _normalize_elements(elements, state = false)
        count = 0
        retval = elements.reject do |elem|
          if @ignore_text && elem.kind_of?(Hpricot::Text) then
            true
          elsif elem.kind_of?(Hpricot::Comment) then
            true
          elsif elem.kind_of?(Hpricot::Elements) then
            elem.reject!{|e| _normalize_elements(e, state)}
            elem.empty?
          elsif elem.kind_of?(Hpricot::Elem) then
            new_state = false
            if elem.name == 'test' ||
                elem.name == 'edit' ||
                elem.name == 'alias' then
              new_state = true
            elsif state &&
                (elem.name == 'string' ||
                 elem.name == 'family') then
              count += 1
            end
            children = elem.children
            elem.children = _normalize_elements(children, new_state)
            (state && count > 1)
          end
        end
        retval
      end # def _normalize_elements

    end # class 

    def initialize(file)
      File.open(file) do |f|
        x = f.read
        @doc = Hpricot.XML(x)
      end
      @ignore_attributes = false
      @ignore_text = true
    end # def initialize

    attr_accessor :ignore_attributes, :ignore_text

    def include?(reference, opts = {})
      a = _get_element(reference, opts)
      !a.empty?
    end # def include?

    def has_alias?(name)
      !entity_of_alias(name).nil?
    end # def has_alias?

    def entity_of_alias(name)
      name = "sans-serif" if name == "sans"
      generic_names_rule = Hpricot.XML("<fontconfig><alias><family>Name of your font</family><default><family>Generic like sans-serif, serif, monospace, fantasy or cursive</family></default></alias></fontconfig>")
      _get_element(generic_names_rule).each do |elems|
        e = elems.search('family')
        if e[1].inner_text.downcase == name.downcase then
          return e[0].inner_text
        end
      end

      nil
    end # def entity_of_alias

    def to_a
      r = (@doc/"fontconfig/*").reject do |elem|
        if elem.kind_of?(Hpricot::Comment) ||
            @ignore_text && elem.kind_of?(Hpricot::Text) then
          true
        else
          false
        end
      end
      ::FontPackages::FontconfigElements.new(r)
    end # def to_a

    private

    def _get_element(reference, opts = {})
      retval = []
      # make a clone of the object since normalize method breaks the object.
      ref = Hpricot.XML(reference.inner_html)
      ::FontPackages::Fontconfig.normalize(ref/"fontconfig/*", @ignore_text) if opts.include?(:normalize) && opts[:normalize]
      (ref/"fontconfig/*").each do |xelement|
        next if @ignore_text && xelement.kind_of?(Hpricot::Text)
        next if xelement.kind_of?(Hpricot::Comment)
        x = ::FontPackages::FontconfigElement.new(xelement)
        x.ignore_attributes = @ignore_attributes
        x.ignore_text = @ignore_text
        path = xelement.xpath.sub(/\A\//, '').sub(/\[\d+\]\Z/, '')
        doc = Hpricot.XML(@doc.inner_html)
        ::FontPackages::Fontconfig.normalize(doc/"fontconfig/*", @ignore_text) if opts.include?(:normalize) && opts[:normalize]
        yelems = (doc/path).reject do |yelem|
          y = ::FontPackages::FontconfigElement.new(yelem)
          y.ignore_attributes = @ignore_attributes
          y.ignore_text = @ignore_text
          x != y
        end
        retval << yelems
      end
      retval.flatten
    end # def _get_element

  end # class Fontconfig

end # module FontPackages


if $0 == __FILE__ then
  require 'pp'

  z = FontPackages::Fontconfig.new('/etc/fonts/conf.d/65-0-vlgothic-pgothic.conf')
  e = Hpricot.XML(File.open("/usr/share/fontconfig/templates/l10n-font-template.conf").read)
  p z.include?(e)
  e = Hpricot.XML(File.open("/usr/share/fontconfig/templates/basic-font-template.conf").read)
  p z.include?(e)
  ##
  a = Hpricot.XML("<alias><family>foo</family><prefer><family>foo</family></prefer></alias")
  aa = FontPackages::FontconfigElement.new((a/"/")[0])
  b = Hpricot.XML("<alias><family>foo</family><default><family>foo</family></default></alias>")
  bb = FontPackages::FontconfigElement.new((b/"/")[0])
  c = Hpricot.XML("<alias><family>bar</family><prefer><family>bar</family></prefer></alias")
  cc = FontPackages::FontconfigElement.new((c/"/")[0])
  d = Hpricot.XML("<alias target=\"font\"><family>bar</family><prefer><family>bar</family></prefer></alias")
  dd = FontPackages::FontconfigElement.new((d/"/")[0])
  e = Hpricot.XML("<alias><family>foo</family><accept><family>bar</family></accept>")
  ee = FontPackages::FontconfigElement.new((e/"/")[0])
  f = Hpricot.XML("<alias><family>foo</family><accept><family>bar</family><family>baz</family></accept>")
  ff = FontPackages::FontconfigElement.new((f/"/")[0])
  p "# aa: prefer list"
  p "# bb: generic name"
  p "# cc: prefer list w/ different text"
  p "# dd: prefer list w/ attr"
  p "# ee: font substitution"
  p "# ff: font substitution w/ multiple subst"
  p "aa == bb: #{aa == bb}: #{(aa == bb) ? 'NG' : 'OK'}"
  p "aa == aa: #{aa == aa}: #{(aa == aa) ? 'OK' : 'NG'}"
  p "aa == cc: #{aa == cc}: #{(aa == cc) ? 'OK' : 'NG'}"
  p "cc == dd: #{cc == dd}: #{(cc == dd) ? 'NG' : 'OK'}"
  cc.ignore_attributes = true
  dd.ignore_attributes = true
  p "cc == dd(no attr): #{cc == dd}: #{(cc == dd) ? 'OK' : 'NG'}"
  aa.ignore_text = false
  cc.ignore_text = false
  p "aa == cc(w/ txt): #{aa == cc}: #{(aa == cc) ? 'NG' : 'OK'}"
  p "cc == cc(w/ txt): #{cc == cc}: #{(cc == cc) ? 'OK' : 'NG'}"
  p "ee == ff: #{ee == ff}: #{(ee == ff) ? 'OK' : 'NG'}"
  zz = z.to_a
  e = Hpricot.XML(File.open("/usr/share/fontconfig/templates/l10n-font-template.conf").read)
  zz -= e
  p "# zz: array of 65-0-vlgothic-pgothic-fonts.conf"
  p "zz - e: #{zz.length}: #{(zz.length == 1) ? 'OK' : 'NG'}"
end
