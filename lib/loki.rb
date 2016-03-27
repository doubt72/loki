require 'pp'

require 'loki/utilities'
require 'loki/page'
require 'loki/metadata'

class Loki
  def self.generate(source_path, dest_path)
    check_paths(source_path, dest_path)

    manifest = Loki::Utilities.tree(File.join(source_path, 'views'))

    puts "manifest:"
    pp(manifest)
    puts ""

    manifest.each do |page|
      Page.generate(source_path, dest_path, page)
    end
  end

  def self.check_paths(source_path, dest_path)
    if (!Dir.exists?(source_path))
      Loki::Utilities.error("Source path must exist.", true)
    end
    if (!Dir.exists?(dest_path))
      Loki::Utilities.error("Destination path must exist.", true)
    end
    if (source_path == dest_path)
      msg = "Destination path must be different from source path."
      Loki::Utilities.error(msg, true)
    end

    %w(views assets components).each do |dir|
      path = File.join(source_path, dir)
      if !Dir.exists?(path)
        Loki::Utilities.error("Source directory #{path} must exist.")
      end
    end
  end
end

