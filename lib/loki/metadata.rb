class Loki
  class Metadata
    def self.eval(data, page)
      begin
        @@current_page = page
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
      Loki::Utilities.error("Error parsing metadata: #{msg}")
    end

    class << self
      def method_missing(name, *args, &block)
        error("invalid parameter '#{name}'")
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
