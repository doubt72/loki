require 'fileutils'

class Loki
  class Page
    attr_reader :__source_root, :__destination_root, :__path_components
    attr_accessor :__body, :__html

    META_SYMBOLS = %i(id title template tags css javascript)
    META_TYPES = %i(string string string string_array string_array
                    string_array)

    META_SYMBOLS.each do |attr|
      self.send(:attr_accessor, attr)
    end

    def initialize(source_root, destination_root, page)
      @__source_root = source_root
      @__destination_root = destination_root
      @__path_components = page
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

    def set(key, value, &block)
      self.class.send(:attr_accessor, key)
      self.send(key.to_s + '=', value)
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

    def __init_manual_data(data)
      @manual_data = Loki::Manual.new(data, self)
    end

    def __manual_data
      @manual_data
    end

    def __validate_type(parameter, type)
      value = send(parameter)
      if (value.nil?)
        return
      end
      case type
      when :string
        if (value.class != String)
          __type_error(parameter, value, type)
        end
      when :string_array
        if (value.class != Array)
          __type_error(parameter, value, type)
        end
        value.each do |item|
          if (item.class != String)
            __type_error("tag", item, :string)
          end
        end
      else
        msg = "Internal error: undefined metadata type #{type}"
        Loki::Utils.error(msg)
      end
    end

    def __type_error(parameter, value, type)
      msg = "Invalid type for #{parameter}: " +
        "expecting #{type}, got '#{value}'"
      Loki::Utils.error(msg)
    end
  end
end
