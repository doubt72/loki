class Loki
  class Page
    attr_accessor :source, :dest

    META_SYMBOLS = %i(id title template tags)
    META_TYPES = %i(string string string string_array)

    META_SYMBOLS.each do |attr|
      self.send(:attr_accessor, attr)
    end

    def self.generate(source_root, dest_root, path)
      page = Page.new

      page.source = File.join(source_root, 'views', path)
      page.dest = File.join(dest_root, path) + ".html"

      puts "page: #{page.source} -> #{page.dest}"

      page.build

      puts ""
    end

    def build
      file = File.read(source)

      meta = file[/^.*\n--\n/m]
      if (meta)
        meta = meta.gsub(/\n--\n$/m,'')
        Loki::Metadata.eval(meta, self)

        0.upto(META_SYMBOLS.length - 1) do |x|
          validate_type(META_SYMBOLS[x], META_TYPES[x])
        end
      end

      body = file.gsub(/^.*\n--\n/,'')
    end

    def validate_type(parameter, type)
      value = send(parameter)
      if (value.nil?)
        return
      end
      case type
      when :string
        if (value.class != String)
          type_error(parameter, value, type)
        end
      when :string_array
        if (value.class != Array)
          type_error(parameter, value, type)
        end
        value.each do |item|
          if (item.class != String)
            type_error("tag", item, :string)
          end
        end
      else
        msg = "Internal error: undefined metadata type #{type}"
        Loki::Utilities.error(msg)
      end
    end

    def type_error(parameter, value, type)
      msg = "Invalid type for #{parameter}: " +
        "expecting #{type}, got '#{value}'"
      Loki::Utilities.error(msg)
    end
  end
end
