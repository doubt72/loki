class Loki
  class PageProcessor
    def initialize(page)
      @page = page
    end

    # Internal functions use '__' to avoid collisions with possible user-defined
    # metadata and such, though in a pinch users COULD access if they understood
    # the internals sufficiently. Not worth the bother to prevent, really, this
    # is just to avoid accidents.
    def __process
      @context = :template

      # If we have a template, we process that, otherwise we process the page
      if (@page.template.nil?)
        @context = :body
        html = __parse(@page.__body, @page.__source_path)
      else
        puts "- using template: #{@page.template}"
        html = __parse(Loki::Utils.load_component(@page.__source_root,
                                                  @page.template),
                       File.join(@page.__source_root, 'components',
                                 @page.template))
      end

      html = "<body>\n#{html}</body>\n"

      # Handle all the header stuff; title, css, js, etc.
      head = ""
      if (@page.title)
        head = "  <title>#{@page.title}</title>\n"
      end
      if (@page.css)
        @page.css.each do |css|
          css_path = __make_relative_path("assets/#{css}",
                                          @page.__destination_path)
          head += "  <link rel=\"stylesheet\" href=\"#{css_path}\" " +
            "type=\"text/css\" />\n"
          Loki::Utils.copy_asset(@page.__source_root,
                                 @page.__destination_root, css)
        end
      end
      if (@page.javascript)
        @page.javascript.each do |js|
          js_path = __make_relative_path("assets/#{js}",
                                          @page.__destination_path)
          head += "  <script src=\"#{js_path}\" type=\"text/javascript\">" +
            "</script>\n"
          Loki::Utils.copy_asset(@page.__source_root,
                                 @page.__destination_root, js)
        end
      end
      if (head.length > 0)
        html = "<head>\n#{head}</head>\n#{html}"
      end
      # TODO: deal with headers

      @page.__html = "<html>\n#{html}</html>\n"
    end

    def __parse(source, path)
      path = path
      line = 1
      html = ""
      inside_eval_context = false
      checking_for_escape = false
      buffer = ""
      0.upto(source.length - 1) do |index|
        char = source[index]
        if (char == "\n")
          line += 1
        end
        if inside_eval_context
          if (char == '}' && checking_for_escape)
            checking_for_escape = false
            buffer += char
          elsif (char == '}' && source[index + 1] == '}')
            checking_for_escape = true
          elsif (char == '}')
            inside_eval_context = false
            begin
              @parse_path = path
              @parse_line = line
              html += String(__eval(buffer))
            rescue Exception => e
              raise "#{e}\nEvaluation context: {#{buffer}}\n\n"
            end
            buffer = ""
          else
            buffer += char
            if (buffer == "{")
              inside_eval_context = false
              html += "{"
              buffer = ""
            end
          end
        else
          if (char == '{')
            inside_eval_context = true
          else
            html += char
          end
        end
      end
      if inside_eval_context
        @parse_path = path
        @parse_line = line
        __error("unexpected end-of-file; no matching '}'")
      end

      html
    end

    def __eval(data)
      begin
        instance_eval data
      rescue Exception => e
        if (e.message =~ /^Error on line.*of file/)
          raise e
        else
          __error("\n#{e}")
        end
      end
    end

    def __error(msg)
      Loki::Utils.error("Error on line #{@parse_line} of " +
                        "file #{@parse_path}:\n#{msg}")
    end

    def method_missing(name, *args, &block)
      __error("invalid directive '#{name}'")
    end

    # Template insert body
    def body
      if (@context == :body)
        __error("attempt to include body outside of template")
      end
      @context = :body
      __parse(@page.__body, @page.__source_path)
    end

    # Include a file
    def include(path, &block)
      puts "- including partial: #{path}"
      __parse(Loki::Utils.load_component(@page.__source_root, path),
        File.join(@page.__source_root, 'components', path))
    end

    # Absolute link
    def link_abs(url, text, options = {})
      rc = "<a href=\"#{url}\""
      rc += __handle_options(options)
      rc + ">#{text}</a>"
    end

    # Relative link
    def link(id, text, options = {})
      path = @page.__site.__lookup_path(@page.__source_root,
      @page.__destination_root, id)

      path = __make_relative_path(path, @page.__destination_path)
      if (options[:append])
        path += options[:append]
      end

      if (options[:self_class] && id == @page.id)
        if (options[:class])
          options[:class] = "#{options[:self_class]} #{options[:class]}"
        else
          options[:class] = options[:self_class]
        end
      end

      link_abs(path, text, options)
    end

    # Image
    def image(path, options = {})
      Loki::Utils.copy_asset(@page.__source_root,
        @page.__destination_root, path)
      img_path = __make_relative_path("assets/#{path}",
        @page.__destination_path)
      rc = "<img src=\"#{img_path}\""
      if (options[:alt])
        rc += " alt=\"#{options[:alt]}\""
      end
      rc += __handle_options(options)
      rc + " />"
    end

    # Simple table
    def table(data, options = {})
      rc = "<table"
      rc += __handle_options(options)
      rc += ">\n"
      if (data.class != Array)
        __error("table data must be an array")
      end
      data.each do |row|
        if (row.class != Array)
          __error("rows of table data must all be arrays")
        end
        rc += "  <tr>\n"
        row.each do |item|
          rc += "    <td>#{item}</td>\n"
        end
        rc += "  </tr>\n"
      end
      rc + "</table>\n"
    end

    # Relative link to manual section
    def manual_ref(path, text = nil)
      if (@page.__manual_data.nil?)
        __error("no manual data defined, cannot create link")
      end
      if (text.nil?)
        text = path.split('|')[-1]
      end
      "<a href=\"##{@page.__manual_data.name_to_section_index(path)}\">#{text}</a>"
    end

    # Render full manual
    def render_manual
      if (@page.__manual_data.nil?)
        __error("no manual data defined, cannot render")
      end
      @page.__manual_data.render
    end

    def __make_relative_path(path, here)
      path_parts = path.split("/")[0 .. -2]
      here_parts = here.split("/")[1 .. -2]

      target = path.split("/")[-1]

      while(path_parts.length > 0 && here_parts.length > 0 &&
        path_parts[0] == here_parts[0])
        path_parts = path_parts[1 .. -1]
        here_parts = here_parts[1 .. -1]
      end

      new_parts = here_parts.collect {|x| '..'}
      new_parts += path_parts
      new_parts.push(target)

      new_parts.join("/")
    end

    # Page
    def page
      @page
    end

    # Site
    def site
      @page.__site
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
