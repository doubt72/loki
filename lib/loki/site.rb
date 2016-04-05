class Loki
  class Site
    def initialize
      @pages = []
    end

    def set(key, value, &block)
      self.class.send(:attr_accessor, key)
      self.send(key.to_s + '=', value)
    end

    def __eval(data, path)
      begin
        instance_eval data
      rescue Exception => e
        Loki::Utils.error("Error reading #{path}:\n#{e}")
      end
    end

    def __read_eval(path)
      if File.exists?(path)
        file = File.read(path)
        __eval(file, path)
      end
    end

    def __read_config_rb(source_root)
      __read_eval(File.join(source_root, 'config.rb'))
    end

    def __read_config_load_rb(source_root)
      __read_eval(File.join(source_root, 'config_load.rb'))
    end

    def __add_page(page)
      @pages.push(page)
    end

    def __load_pages
      ids = []

      @pages.each do |page|
        page.__load(self)
        if (page.id)
          if ids.include?(page.id)
            Loki::Utils.error("Error loading page: " +
                              "duplicate id '#{page.id}'")
          else
            ids.push(page.id)
          end
        end
      end
    end

    def __build_pages
      @pages.each do |page|
        page.__build(self)
      end
    end

    def __lookup_path(source, dest, id)
      # first look up 
      @pages.each do |page|
        if (page.id && id == page.id)
          return page.path_components.join("/") + ".html"
        end
      end

      source_path = File.join(source, 'assets', id)
      if File.exists?(source_path)
        Loki::Utils.copy_asset(source, dest, id)
        return "assets/#{id}"
      end

      Loki::PageProcessor.__error("couldn't link to '#{id}', no match found.")
    end
  end
end
