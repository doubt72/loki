require 'fileutils'

class Loki
  class Page
    attr_accessor :source_root, :destination_root, :path_components
    attr_accessor :body, :html

    META_SYMBOLS = %i(id title template tags css javascript)
    META_TYPES = %i(string string string string_array string_array
                    string_array)

    META_SYMBOLS.each do |attr|
      self.send(:attr_accessor, attr)
    end

    def initialize(source_root, destination_root, page)
      @source_root = source_root
      @destination_root = destination_root
      @path_components = page
    end

    def __load(site)
      puts "loading source: #{source_path}"

      file = File.read(source_path)

      meta = file[/^.*?\n--\n/m]
      if (meta)
        meta = meta.gsub(/\n--\n$/m,'')
        Loki::MetadataProcessor.eval(meta, self, site)

        0.upto(META_SYMBOLS.length - 1) do |x|
          __validate_type(META_SYMBOLS[x], META_TYPES[x])
        end
      end

      @body = file.gsub(/^.*?\n--\n/m,'')
    end

    def __build(site)
      puts "page: #{source_path} ->"

      Loki::PageProcessor.__process(self, site)

      dir = File.dirname(destination_path)
      FileUtils.mkdir_p(dir)
      puts "- writing: #{destination_path}"
      File.write(destination_path, html)

      puts ""
    end

    def set(key, value, &block)
      self.class.send(:attr_accessor, key)
      self.send(key.to_s + '=', value)
    end

    def source_path
      File.join(source_root, 'views', path_components)
    end

    def destination_path
      File.join(destination_root, path_components) + ".html"
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
