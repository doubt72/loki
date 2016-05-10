require 'fileutils'

class Loki
  class Utils
    def self.tree(path, list = [])
      files = []
      Dir.entries(path).each do |file|
        if (file == '.' || file == '..')
          next
        end

        branch = File.join(path, file)
        if (Dir.exists?(branch))
          files += tree(branch, list + [file])
        else
          files.push(list + [file])
        end
      end
      return files
    end

    def self.load_component(source, path)
      source_path = File.join(source, 'components', path)

      if !File.exists?(source_path)
        error("Error loading component: #{source_path} doesn't exist.")
      end
      File.read(source_path)
    end

    def self.copy_asset(source, dest, path)
      source_path = File.join(source, 'assets', path)
      dest_path = File.join(dest, 'assets', path)

      puts "- copy asset: #{source_path} ->\n    #{dest_path}"

      if !File.exists?(source_path)
        error("Error copying file: #{source_path} doesn't exist.")
      end

      dir = File.dirname(dest_path)
      FileUtils.mkdir_p(dir)
      FileUtils.cp(source_path, dest_path)
    end

    def self.error(message, show_usage = false)
      error_message = message + "\n\n"
      error_message += usage if show_usage
      raise StandardError, error_message
    end

    def self.usage
      "Usage: loki <source> <destination>\n\n"
    end

    def self.validate_type(parameter, value, type)
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
      when :favicon_array
        if (value.class != Array)
          type_error(parameter, value, type)
        end
        value.each do |item|
          if (item.class != Array)
            type_error("favicon spec", item, :array)
          end
          if (item[0].class != Fixnum)
            type_error("favicon size", item[0], :integer)
          end
          if (item[1].class != String)
            type_error("favicon type", item[1], :string)
          end
          if (item[2].class != String)
            type_error("favicon path", item[2], :string)
          end
        end
      else
        msg = "Internal error: undefined metadata type #{type}"
        Loki::Utils.error(msg)
      end
    end

    def self.type_error(parameter, value, type)
      msg = "Invalid type for #{parameter}: " +
        "expecting #{type}, got '#{value}'"
      Loki::Utils.error(msg)
    end
  end
end
