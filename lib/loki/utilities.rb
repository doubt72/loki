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
  end
end
