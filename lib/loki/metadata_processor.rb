class Loki
  class MetadataProcessor
    def initialize(page)
      @page = page
    end

    # Internal functions use '__' to avoid collisions with possible user-defined
    # metadata and such, though in a pinch users COULD access if they understood
    # the internals sufficiently. Not worth the bother to prevent, really, this
    # is just to avoid accidents.
    def __eval(data)
      begin
        instance_eval data
      rescue Exception => e
        if (e.message =~ /^Error parsing metadata/)
          raise e
        else
          __error("\n#{e}")
        end
      end
    end

    def __error(msg)
      Loki::Utils.error("Error parsing metadata: #{msg}")
    end

    def method_missing(name, *args, &block)
      __error("invalid parameter '#{name}'")
    end

    def set(key, value, &block)
      @page.class.send(:attr_accessor, key)
      @page.send(key.to_s + '=', value)
    end

    def global(key, value, &block)
      @page.__site.class.send(:attr_accessor, key)
      @page.__site.send(key.to_s + '=', value)
    end

    def page
      @page
    end

    def site
      @page.__site
    end

    def manual_data(data)
      @page.__init_manual_data(data)
    end

    # Define functions to set all the standard metadata for a page so we don't
    # have to redifine that in two places, we use a standard list that's
    # controlled by the Page class
    (Loki::Page::META_SYMBOLS + Loki::BlogEntry::META_SYMBOLS).each do |call|
      define_method(call) do |value = nil, &block|
        result = value
        if (block)
          result = block.call
        end
        if (result)
          @page.send(call.to_s + '=', result)
        end
      end
    end
  end
end
