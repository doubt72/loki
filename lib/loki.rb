require 'pp'

require 'loki/utilities'

class Loki
  def self.generate(source_path, dest_path)
    check_paths(source_path, dest_path)

    manifest = Loki::Utilities.tree(File.join(source_path, 'views'))
    assets = Loki::Utilities.tree(File.join(source_path, 'assets'))
    components = Loki::Utilities.tree(File.join(source_path, 'components'))

    puts "manifest:"
    pp(manifest)
  end

  def self.check_paths(source_path, dest_path)
    if (!Dir.exists?(source_path))
      puts "Source path must exist."
      usage
    end
    if (!Dir.exists?(dest_path))
      puts "Destination path must exist."
      usage
    end
    if (source_path == dest_path)
      puts "Destination path must be different from source path."
      usage
    end
  end

  def self.usage
    puts "\nUsage: loki <source> <destination>"
    puts ""
    exit
  end
end

