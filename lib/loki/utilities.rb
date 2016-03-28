require 'fileutils'

class Loki
  class Utilities
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

      puts "- copy asset: #{source_path} -> #{dest_path}"

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
  end
end
