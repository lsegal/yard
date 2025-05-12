# frozen_string_literal: false
#
# httputils.rb -- HTTPUtils Module
#
# Author: IPR -- Internet Programming with Ruby -- writers
# Copyright (c) 2000, 2001 TAKAHASHI Masayoshi, GOTOU Yuuzou
# Copyright (c) 2002 Internet Programming with Ruby writers. All rights
# reserved.
#
# $IPR: httputils.rb,v 1.34 2003/06/05 21:34:08 gotoyuzo Exp $

require 'socket'
require 'tempfile'

module YARD::Server
  CR   = "\x0d"     # :nodoc:
  LF   = "\x0a"     # :nodoc:
  CRLF = "\x0d\x0a" # :nodoc:

  ##
  # HTTPUtils provides utility methods for working with the HTTP protocol.
  #
  # This module is generally used internally by WEBrick

  module HTTPUtils
    ##
    # Normalizes a request path.  Raises an exception if the path cannot be
    # normalized.

    def normalize_path(path)
      raise "abnormal path `#{path}'" if path[0] != '/'
      ret = path.dup

      ret.gsub!(%r{/+}o, '/')                    # //      => /
      while ret.sub!(%r{/\.(?:/|\Z)}, '/'); end  # /.      => /
      while ret.sub!(%r{/(?!\.\./)[^/]+/\.\.(?:/|\Z)}, '/'); end # /foo/.. => /foo

      raise "abnormal path `#{path}'" if %r{/\.\.(/|\Z)} =~ ret
      ret
    end
    module_function :normalize_path

    ##
    # Default mime types

    DefaultMimeTypes = {
      "ai"    => "application/postscript",
      "asc"   => "text/plain",
      "avi"   => "video/x-msvideo",
      "bin"   => "application/octet-stream",
      "bmp"   => "image/bmp",
      "class" => "application/octet-stream",
      "cer"   => "application/pkix-cert",
      "crl"   => "application/pkix-crl",
      "crt"   => "application/x-x509-ca-cert",
      # "crl"   => "application/x-pkcs7-crl",
      "css"   => "text/css",
      "dms"   => "application/octet-stream",
      "doc"   => "application/msword",
      "dvi"   => "application/x-dvi",
      "eps"   => "application/postscript",
      "etx"   => "text/x-setext",
      "exe"   => "application/octet-stream",
      "gif"   => "image/gif",
      "htm"   => "text/html",
      "html"  => "text/html",
      "jpe"   => "image/jpeg",
      "jpeg"  => "image/jpeg",
      "jpg"   => "image/jpeg",
      "js"    => "application/javascript",
      "json"  => "application/json",
      "lha"   => "application/octet-stream",
      "lzh"   => "application/octet-stream",
      "mjs"   => "application/javascript",
      "mov"   => "video/quicktime",
      "mpe"   => "video/mpeg",
      "mpeg"  => "video/mpeg",
      "mpg"   => "video/mpeg",
      "pbm"   => "image/x-portable-bitmap",
      "pdf"   => "application/pdf",
      "pgm"   => "image/x-portable-graymap",
      "png"   => "image/png",
      "pnm"   => "image/x-portable-anymap",
      "ppm"   => "image/x-portable-pixmap",
      "ppt"   => "application/vnd.ms-powerpoint",
      "ps"    => "application/postscript",
      "qt"    => "video/quicktime",
      "ras"   => "image/x-cmu-raster",
      "rb"    => "text/plain",
      "rd"    => "text/plain",
      "rtf"   => "application/rtf",
      "sgm"   => "text/sgml",
      "sgml"  => "text/sgml",
      "svg"   => "image/svg+xml",
      "tif"   => "image/tiff",
      "tiff"  => "image/tiff",
      "txt"   => "text/plain",
      "wasm"  => "application/wasm",
      "xbm"   => "image/x-xbitmap",
      "xhtml" => "text/html",
      "xls"   => "application/vnd.ms-excel",
      "xml"   => "text/xml",
      "xpm"   => "image/x-xpixmap",
      "xwd"   => "image/x-xwindowdump",
      "zip"   => "application/zip"
    }

    ##
    # Loads Apache-compatible mime.types in +file+.

    def load_mime_types(file)
      # NOTE: +file+ may be a "| command" for now; some people may
      # rely on this, but currently we do not use this method by default.
      open(file) do |io|
        hash = {}
        io.each do |line|
          next if /^#/ =~ line
          line.chomp!
          mimetype, ext0 = line.split(/\s+/, 2)
          next unless ext0
          next if ext0.empty?
          ext0.split(/\s+/).each {|ext| hash[ext] = mimetype }
        end
        hash
      end
    end
    module_function :load_mime_types

    ##
    # Returns the mime type of +filename+ from the list in +mime_tab+.  If no
    # mime type was found application/octet-stream is returned.

    def mime_type(filename, mime_tab)
      suffix1 = /\.(\w+)$/ =~ filename && $1.downcase
      suffix2 = /\.(\w+)\.[\w\-]+$/ =~ filename && $1.downcase
      mime_tab[suffix1] || mime_tab[suffix2] || "application/octet-stream"
    end
    module_function :mime_type

    ##
    # Parses an HTTP header +raw+ into a hash of header fields with an Array
    # of values.

    def parse_header(raw)
      header = Hash.new([].freeze)
      field = nil
      raw.each_line do |line|
        case line
        when /^([A-Za-z0-9!\#$%&'*+\-.^_`|~]+):\s*(.*?)\s*\z/om
          field = $1
          value = $2
          field.downcase!
          header[field] = [] unless header.key?(field)
          header[field] << value
        when /^\s+(.*?)\s*\z/om
          value = $1
          raise HTTPStatus::BadRequest, "bad header '#{line}'." unless field
          header[field][-1] << " " << value
        else
          raise HTTPStatus::BadRequest, "bad header '#{line}'."
        end
      end
      header.each do |_key, values|
        values.each(&:strip!)
      end
      header
    end
    module_function :parse_header

    ##
    # Splits a header value +str+ according to HTTP specification.

    def split_header_value(str)
      str.scan(/\G((?:"(?:\\.|[^"])+?"|[^",]+)+)
                    (?:,\s*|\Z)/xn).flatten
    end
    module_function :split_header_value

    ##
    # Parses a Range header value +ranges_specifier+

    def parse_range_header(ranges_specifier)
      if /^bytes=(.*)/ =~ ranges_specifier
        byte_range_set = split_header_value($1)
        byte_range_set.collect do |range_spec|
          case range_spec
          when /^(\d+)-(\d+)/ then $1.to_i..$2.to_i
          when /^(\d+)-/      then $1.to_i..-1
          when /^-(\d+)/      then -$1.to_i..-1
          else return nil
          end
        end
      end
    end
    module_function :parse_range_header

    ##
    # Parses q values in +value+ as used in Accept headers.

    def parse_qvalues(value)
      tmp = []
      if value
        parts = value.split(/,\s*/)
        parts.each do |part|
          next unless (m = /^([^\s,]+?)(?:;\s*q=(\d+(?:\.\d+)?))?$/.match(part))
          val = m[1]
          q = (m[2] or 1).to_f
          tmp.push([val, q])
        end
        tmp = tmp.sort_by {|_val, q| -q }
        tmp.collect! {|val, _q| val }
      end
      tmp
    end
    module_function :parse_qvalues

    ##
    # Removes quotes and escapes from +str+

    def dequote(str)
      ret = /\A"(.*)"\Z/ =~ str ? $1 : str.dup
      ret.gsub!(/\\(.)/, "\\1")
      ret
    end
    module_function :dequote

    ##
    # Quotes and escapes quotes in +str+

    def quote(str)
      '"' << str.gsub(/[\\\"]/o, "\\\1") << '"'
    end
    module_function :quote

    ##
    # Stores multipart form data.  FormData objects are created when
    # WEBrick::HTTPUtils.parse_form_data is called.

    class FormData < String
      EmptyRawHeader = [].freeze # :nodoc:
      EmptyHeader = {}.freeze # :nodoc:

      ##
      # The name of the form data part

      attr_accessor :name, :filename, :next_data

      ##
      # The filename of the form data part # :nodoc:
      protected :next_data

      ##
      # Creates a new FormData object.
      #
      # +args+ is an Array of form data entries.  One FormData will be created
      # for each entry.
      #
      # This is called by WEBrick::HTTPUtils.parse_form_data for you

      def initialize(*args)
        @name = @filename = @next_data = nil
        if args.empty?
          @raw_header = []
          @header = nil
          super("")
        else
          @raw_header = EmptyRawHeader
          @header = EmptyHeader
          super(args.shift)
          @next_data = self.class.new(*args) unless args.empty?
        end
      end

      ##
      # Retrieves the header at the first entry in +key+

      def [](*key)
        @header[key[0].downcase].join(", ")
      rescue StandardError, NameError
        super
      end

      ##
      # Adds +str+ to this FormData which may be the body, a header or a
      # header entry.
      #
      # This is called by WEBrick::HTTPUtils.parse_form_data for you

      def <<(str)
        if @header
          super
        elsif str == CRLF
          @header = HTTPUtils.parse_header(@raw_header.join)
          if (cd = self['content-disposition'])
            if /\s+name="(.*?)"/ =~ cd then @name = $1 end
            if /\s+filename="(.*?)"/ =~ cd then @filename = $1 end
          end
        else
          @raw_header << str
        end
        self
      end

      ##
      # Adds +data+ at the end of the chain of entries
      #
      # This is called by WEBrick::HTTPUtils.parse_form_data for you.

      def append_data(data)
        tmp = self
        while tmp
          unless tmp.next_data
            tmp.next_data = data
            break
          end
          tmp = tmp.next_data
        end
        self
      end

      ##
      # Yields each entry in this FormData

      def each_data
        tmp = self
        while tmp
          next_data = tmp.next_data
          yield(tmp)
          tmp = next_data
        end
      end

      ##
      # Returns all the FormData as an Array

      def list
        ret = []
        each_data do |data|
          ret << data.to_s
        end
        ret
      end

      ##
      # A FormData will behave like an Array

      alias to_ary list

      ##
      # This FormData's body

      def to_s
        String.new(self)
      end
    end

    ##
    # Parses the query component of a URI in +str+

    def parse_query(str)
      query = {}
      if str
        str.split(/[&;]/).each do |x|
          next if x.empty?
          key, val = x.split('=', 2)
          key = unescape_form(key)
          val = unescape_form(val.to_s)
          val = FormData.new(val)
          val.name = key
          if query.key?(key)
            query[key].append_data(val)
            next
          end
          query[key] = val
        end
      end
      query
    end
    module_function :parse_query

    ##
    # Parses form data in +io+ with the given +boundary+

    def parse_form_data(io, boundary)
      boundary_regexp = /\A--#{Regexp.quote(boundary)}(--)?#{CRLF}\z/
      form_data = {}
      return form_data unless io
      data = nil
      io.each_line do |line|
        if boundary_regexp =~ line
          if data
            data.chop!
            key = data.name
            if form_data.key?(key)
              form_data[key].append_data(data)
            else
              form_data[key] = data
            end
          end
          data = FormData.new
          next
        elsif data
          data << line
        end
      end
      form_data
    end
    module_function :parse_form_data

    #####

    reserved = ';/?:@&=+$,'
    num      = '0123456789'
    lowalpha = 'abcdefghijklmnopqrstuvwxyz'
    upalpha  = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    mark     = '-_.!~*\'()'
    unreserved = num + lowalpha + upalpha + mark
    control  = "#{(0x0..0x1f).collect(&:chr).join}\u007F"
    space    = " "
    delims   = '<>#%"'
    unwise   = '{}|\\^[]`'
    nonascii = (0x80..0xff).collect(&:chr).join

    module_function

    # :stopdoc:

    def _make_regex(str) /([#{Regexp.escape(str)}])/n end
    def _make_regex!(str) /([^#{Regexp.escape(str)}])/n end

    def _escape(str, regex)
      str = str.b
      str.gsub!(regex) { "%%%02X" % $1.ord }
      # %-escaped string should contain US-ASCII only
      str.force_encoding(Encoding::US_ASCII)
    end

    def _unescape(str, regex)
      str = str.b
      str.gsub!(regex) { $1.hex.chr }
      # encoding of %-unescaped string is unknown
      str
    end

    UNESCAPED = _make_regex(control + space + delims + unwise + nonascii)
    UNESCAPED_FORM = _make_regex(reserved + control + delims + unwise + nonascii)
    NONASCII  = _make_regex(nonascii)
    ESCAPED   = /%([0-9a-fA-F]{2})/
    UNESCAPED_PCHAR = _make_regex!("#{unreserved}:@&=+$,")

    # :startdoc:

    ##
    # Escapes HTTP reserved and unwise characters in +str+

    def escape(str)
      _escape(str, UNESCAPED)
    end

    ##
    # Unescapes HTTP reserved and unwise characters in +str+

    def unescape(str)
      _unescape(str, ESCAPED)
    end

    ##
    # Escapes form reserved characters in +str+

    def escape_form(str)
      ret = _escape(str, UNESCAPED_FORM)
      ret.tr!(' ', "+")
      ret
    end

    ##
    # Unescapes form reserved characters in +str+

    def unescape_form(str)
      _unescape(str.tr('+', " "), ESCAPED)
    end

    ##
    # Escapes path +str+

    def escape_path(str)
      result = ""
      str.scan(%r{/([^/]*)}).each do |i|
        result << "/" << _escape(i[0], UNESCAPED_PCHAR)
      end
      result
    end

    ##
    # Escapes 8 bit characters in +str+

    def escape8bit(str)
      _escape(str, NONASCII)
    end
  end
end
