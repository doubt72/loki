require 'pp'

require 'loki/utils'

require 'loki/site'
require 'loki/page'
require 'loki/metadata_processor'
require 'loki/page_processor'

class Loki
  def self.generate(source_path, dest_path)
    check_paths(source_path, dest_path)

    manifest = Loki::Utils.tree(File.join(source_path, 'views'))

    puts "manifest:"
    pp(manifest)
    puts ""

    site = Loki::Site.new

    manifest.each do |page|
      site.add(Loki::Page.new(source_path, dest_path, page))
    end

    puts ""

    site.eval_all
  end

  def self.check_paths(source_path, dest_path)
    if !Dir.exists?(source_path)
      Loki::Utils.error("Source path must exist.", true)
    end
    if !Dir.exists?(dest_path)
      Loki::Utils.error("Destination path must exist.", true)
    end
    if (source_path == dest_path)
      msg = "Destination path must be different from source path."
      Loki::Utils.error(msg, true)
    end

    %w(views assets components).each do |dir|
      path = File.join(source_path, dir)
      if !Dir.exists?(path)
        Loki::Utils.error("Source directory #{path} must exist.")
      end
    end
  end
end

