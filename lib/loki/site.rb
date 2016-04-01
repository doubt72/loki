class Loki
  class Site
    def initialize
      @pages = []
    end

    # loads page on add
    def __add_page(page)
      @pages.push(page)
    end

    def __load_pages
      ids = []

      @pages.each do |page|
        page.load
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
        page.build(self)
      end
    end

    def __lookup_path(source, dest, id)
      # first look up 
      @pages.each do |page|
        if (page.id && id == page.id)
          return page.path.join("/") + ".html"
        end
      end

      source_path = File.join(source, 'assets', id)
      if File.exists?(source_path)
        Loki::Utils.copy_asset(source, dest, id)
        return "assets/#{id}"
      end

      Loki::PageProcessor.error("couldn't link to '#{id}', no match found.")
    end
  end
end
