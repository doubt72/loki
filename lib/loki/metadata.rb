class Loki
  class Metadata
    def self.eval(data, page)
      begin
        @@current_page = page
        instance_eval data
        @@current_page
      rescue Exception => e
        if (e.class == SystemExit)
          exit
        end
        Loki::Utilities.error("Error parsing metadata:\n#{e}")
      end
    end

    def self.method_missing(name, *args, &block)
      msg = "Error parsing metadata: invalid parameter '#{name}'"
      Loki::Utilities.error(msg)
    end

    class << self
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
