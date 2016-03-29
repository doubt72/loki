class Loki
  class Body
    def self.generate(page, state)
      @@context = :template
      @@global_state = state
      @@current_page = page

      if (page.template.nil?)
        @@context = :body
        page.html = __parse(page.body)
      else
        page.html = __parse(Loki::Utilities.load_component(page.source_root,
                                                         page.template))
      end

      page.html = "<body>\n#{page.html}</body>\n"

      head = ""
      if (page.title)
        head = "  <title>#{page.title}</title>\n"
      end
      if (page.css)
        page.css.each do |css|
          head += "  <link rel=\"stylesheet\" href=\"assets/#{css}\" " +
            "type=\"text/css\" />\n"
          Loki::Utilities.copy_asset(page.source_root, page.dest_root, css)
        end
      end
      if (page.javascript)
        page.javascript.each do |js|
          head += "  <script src=\"assets/#{js}\" type=\"text/javascript\">" +
            "</script>\n"
          Loki::Utilities.copy_asset(page.source_root, page.dest_root, js)
        end
      end
      if (head.length > 0)
        page.html = "<head>\n#{head}</head>\n#{page.html}"
      end

      # TODO: deal with headers
      page.html = "<html>\n#{page.html}</html>\n"
    end

    def self.__parse(source)
      html = ""
      inside = false
      buffer = ""
      0.upto(source.length - 1) do |x|
        char = source[x]
        if inside
          if (char == '}')
            inside = false
            html += __eval(buffer)
            buffer = ""
          else
            buffer += char
            if (buffer == "{")
              inside = false
              html += "{"
              buffer = ""
            end
          end
        else
          if (char == '{')
            inside = true
          else
            html += char
          end
        end
      end
      if inside
        error("unexpected end-of-file; no matching '}'")
      end

      html
    end

    def self.__eval(data)
      begin
        instance_eval(data)
      rescue Exception => e
        if (e.message =~ /^Error processing page/)
          raise e
        else
          error("\n#{e}")
        end
      end
    end

    def self.error(msg)
      Loki::Utilities.error("Error processing page: #{msg}")
    end

    class << self
      def method_missing(name, *args, &block)
        error("invalid directive '#{name}'")
      end

      # Template insert body
      def body
        if (@@context == :body)
          error("attempt to include body outside of template")
        end
        @@context = :body
        __parse(@@current_page.body)
      end

      # Include a file
      def include(path, &block)
        __parse(Loki::Utilities.load_component(@@current_page.source_root,
                                             path))
      end

      # Absolute link
      def link_abs(url, text, options = {})
        rc = "<a href=\"#{url}\""
        rc += __handle_options(options)
        rc + ">#{text}</a>"
      end

      # Relative link
      def link(id, text, options = {})
        path = @@global_state.lookup(@@current_page.source_root,
                                     @@current_page.dest_root, id)
        link_abs(path, text, options)
      end

      # Image
      def image(path, options = {})
        Loki::Utilities.copy_asset(@@current_page.source_root,
                                   @@current_page.dest_root, path)
        rc = "<img src=\"#{path}\""
        rc += __handle_options(options)
        rc + " />"
      end

      # Helper functions
      def __handle_options(options = {})
        rc = ""
        if (options[:id])
          rc += " id=\"#{options[:id]}\""
        end
        if (options[:class])
          rc += " class=\"#{options[:class]}\""
        end
        if (options[:style])
          rc += " style=\"#{options[:style]}\""
        end
        rc
      end
    end
  end
end
