require 'fileutils'

class Loki
  class View
    attr_reader :__source_root, :__destination_root, :__path_components
    attr_accessor :__body, :__html

    # List of common metadata values that can be set, along with types for
    # validation; these are also used by the MetadataProcessor class.  These are
    # combined with the values in the child classes, where attr_accessor will be
    # set up.
    META_SYMBOLS = %i(id title tags date)
    META_TYPES = %i(string string string_array string)

    def initialize(source_root, destination_root, path_components)
      @__source_root = source_root
      @__destination_root = destination_root
      @__path_components = path_components
    end

    # For setting new arbitrary metadata; used by the processors
    def set(key, value, &block)
      self.class.send(:attr_accessor, key)
      self.send(key.to_s + '=', value)
    end

    # Internal functions use '__' to avoid collisions with possible user-defined
    # data and such, though in a pinch users COULD access if they understood the
    # internals sufficiently. Not worth the bother to prevent, really, this is
    # just to avoid accidents.
    def __load(site)
      @site = site
      puts "loading source: #{__source_path}"

      file = File.read(__source_path)

      meta = file[/^.*?\n--\n/m]
      if (meta)
        meta = meta.gsub(/\n--\n$/m,'')
        m_proc = Loki::MetadataProcessor.new(self)
        m_proc.__eval(meta)

        0.upto(META_SYMBOLS.length - 1) do |x|
          __validate_type(META_SYMBOLS[x], META_TYPES[x])
        end
      end

      @__body = file.gsub(/^.*?\n--\n/m,'')
    end

    def __build
      puts "page: #{__source_path} ->"

      p_proc = Loki::PageProcessor.new(self)
      p_proc.__process

      dir = File.dirname(__destination_path)
      FileUtils.mkdir_p(dir)
      puts "- writing: #{__destination_path}"
      File.write(__destination_path, __html)

      puts ""
    end

    def __site
      @site
    end

    def __source_path
      File.join(__source_root, 'views', __path_components)
    end

    def __destination_path
      File.join(__destination_root, __path_components) + ".html"
    end

    def __validate_type(parameter, type)
      value = send(parameter)
      Loki::Utils.validate_type(parameter, value, type)
    end
  end
end
