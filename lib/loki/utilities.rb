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

    def self.error(message, show_usage = false)
      puts message
      puts ""

      usage if show_usage

      exit
    end

    def self.usage
      puts "Usage: loki <source> <destination>"
      puts ""
    end
  end
end
