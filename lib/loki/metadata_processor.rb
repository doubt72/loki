class Loki
  class MetadataProcessor
    def self.eval(data, page, site)
      begin
        @@current_page = page
        @@global_site = site
        instance_eval data
        @@current_page
      rescue Exception => e
        if (e.message =~ /^Error parsing metadata/)
          raise e
        else
          error("\n#{e}")
        end
      end
    end

    def self.error(msg)
      Loki::Utils.error("Error parsing metadata: #{msg}")
    end

    class << self
      def method_missing(name, *args, &block)
        error("invalid parameter '#{name}'")
      end

      def set(key, value, &block)
        @@current_page.class.send(:attr_accessor, key)
        @@current_page.send(key.to_s + '=', value)
      end

      def global(key, value, &block)
        @@global_site.class.send(:attr_accessor, key)
        @@global_site.send(key.to_s + '=', value)
      end

      Loki::Page::META_SYMBOLS.each do |call|
        define_method(call) do |value = nil, &block|
          result = value
          if (block)
            result = block.call
          end
          if (result)
            @@current_page.send(call.to_s + '=', result)
          end
        end
      end
    end
  end
end
