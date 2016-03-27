require 'json'

class Loki
  def self.generate(source_path, dest_path)
    check_paths(source_path, dest_path)

    manifest = get_manifest(source_path)

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

  def self.get_manifest(source_path)
    manifest_path = File.join(source_path, "manifest.json")

    if (!File.exists?(manifest_path))
      puts "File manifest.json must exist in source directory."
      usage
    end

    manifest = File.read(manifest_path)
    begin
      validate_manifest(JSON.parse(manifest), true)
    rescue => e
      puts "Error evaluating manifest.json:\n#{e}"
      exit
    end
  end

  def self.validate_manifest(manifest, root = false)
    if (manifest.class != Array)
      msg = "Error parsing manifest.json:\n'#{manifest}' must be array"
      if (!root)
        msg += " or string"
      end
      puts msg
      exit
    end
    manifest.each do |item|
      if (item.class != String)
        validate_manifest(item)
      end
    end
    manifest
  end

  def self.usage
    puts "\nUsage: loki <source> <destination>"
    puts ""
    exit
  end
end

