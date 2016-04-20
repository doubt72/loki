class Loki
  class Manual
    def initialize(data, page)
      @name = data[0]
      @introduction = data[1]
      @page = page

      count = 2
      @sections = []
      data[2..-1].each do |section|
        @sections.push(__make_section(count.to_s, section))
        count += 1
      end
    end

    def __make_section(index, data)
      name = data[0]
      text = data[1]
      section = [name, index, text]
      if (data.length > 2)
        count = 1
        data[2..-1].each do |subsec|
          section.push(__make_section(index + '.' + count.to_s, subsec))
          count += 1
        end
      end

      section
    end

    def name_to_section_index(name)
      if (name == "Introduction")
        return '1'
      end

      index = __find_index(name, @sections)
      if (index.nil?)
        raise "error resolving manual reference: #{name} not found"
      end

      index
    end

    def __find_index(name, subset)
      current, rest = name.split('|', 2)
      subset.each do |section|
        if (section[0] == current)
          if (rest)
            return __find_index(rest, section[3..-1])
          else
            return section[1]
          end
        end
      end

      nil
    end

    def render(path)
      @p_proc = Loki::PageProcessor.new(@page)

      html = "<h1><span id=\"1\"></span>#{@name}</h1>\n"
      html += "#{@p_proc.__parse(@introduction, path)}\n"
      html += "<h2>Contents</h2>\n"
      html += "<ul class=\"toc\">\n"
      html += "<li><a href=\"#1\">1 Introduction</li>\n"
      @sections.each do |section|
        html += __render_section_toc(section)
      end

      html += "</ul>\n"

      @sections.each do |section|
        html += __render_section(section, path, 0)
      end

      html
    end

    def __render_section_toc(section)
      html = "<li><a href=\"##{section[1]}\">"
      html += "<span id=\"ret-#{section[1]}\">"
      html += "#{section[1]}</span> #{section[0]}</a></li>\n"
      if (section.length > 3)
        html += "<ul>\n"
        section[3..-1].each do |subsec|
          html += __render_section_toc(subsec)
        end
        html += "</ul>\n"
      end

      html
    end

    def __render_section(section, path, depth)
      html = "<h#{depth+2}><a href=\"#ret-#{section[1]}\">"
      html += "<span id=\"#{section[1]}\">#{section[1]}</span>"
      html += " #{section[0]}</a></h#{depth+2}>\n"
      html += @p_proc.__parse(section[2], path) + "\n"
      if (section.length > 3)
        section[3..-1].each do |subsec|
          html += __render_section(subsec, path, depth + 1)
        end
      end

      html
    end
  end
end
