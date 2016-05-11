class Loki
  class Site
    attr_accessor :blog

    def initialize
      @ids = []
      @pages = []
      @blog = nil
    end

    # For creating new site-wide metadata values; used by processors
    def set(key, value, &block)
      self.class.send(:attr_accessor, key)
      self.send(key.to_s + '=', value)
    end

    def blog_config(&block)
      @blog = Loki::Blog.new(self)

      # TODO: Kind of a hack; probably should figure out a better way to scope
      # this, but for now this works okay
      @blog_context = @blog
      block.call
      @blog_context = nil
    end

    # Define functions to set all the standard metadata for a blog so we don't
    # have to redifine that in two places, we use a standard list that's
    # controlled by the Blog class
    Loki::Blog::META_SYMBOLS.each do |call|
      define_method(call) do |value = nil, &block|
        result = value
        if (block)
          result = block.call
        end
        if (result)
          # Limit these to blog_config blocks; see blog_config
          if (@blog_context)
            @blog_context.send(call.to_s + '=', result)
          else
            Loki::Utils.error("undefined method #{call.to_s}")
          end
        end
      end
    end

    # Internal functions use '__' to avoid collisions with possible user-defined
    # data and such, though in a pinch users COULD access if they understood the
    # internals sufficiently. Not worth the bother to prevent, really, this is
    # just to avoid accidents.
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

    def __check_and_add_id(id, source = :page)
      if @ids.include?(id)
        type = (source == :page) ? "page" : "blog entry"
        Loki::Utils.error("Error loading #{type}: " +
                          "duplicate id '#{id}'")
      else
        @ids.push(id)
      end
    end

    def __load_pages
      @pages.each do |page|
        page.__load(self)
        if (page.id)
          __check_and_add_id(page.id)
        end
      end
    end

    def __build_pages(source_root, dest_root)
      if (@blog)
        @blog.__load_entries(source_root, dest_root)
        @blog.__build_entries
      end
      @pages.each do |page|
        page.__build
      end
    end

    def __lookup_path(source, dest, id)
      # first look up
      @pages.each do |page|
        if (page.id && id == page.id)
          return page.__path_components.join("/") + ".html"
        end
      end

      source_path = File.join(source, 'assets', id)
      if File.exists?(source_path)
        Loki::Utils.copy_asset(source, dest, id)
        return "assets/#{id}"
      end

      if (@blog)
        @blog.__lookup_path(source, dest, id)
      else
        raise "couldn't link to '#{id}', no match found."
      end
    end

    def __date_sidebar(page)
      @blog.__date_sidebar(page)
    end

    def __tag_sidebar(page)
      @blog.__tag_sidebar(page)
    end

    def __tags
      tags = {}
      @pages.each do |page|
        if (page.tags)
          page.tags.each do |tag|
            if (tags[tag])
              tags[tag] += 1
            else
              tags[tag] = 1
            end
          end
        end
      end
      tags
    end

    def __pages_with_tag(tag)
      pages = []
      @pages.each do |page|
        if (page.tags && page.tags.include?(tag))
          pages.push(page)
        end
      end
      pages
    end
  end
end
