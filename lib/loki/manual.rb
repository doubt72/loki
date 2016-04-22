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

    def render
      @p_proc = Loki::PageProcessor.new(@page)

      manual_section = "#{@page.__source_path} manual section 1 Introduction"

      # Generate a bunch of manual header stuff; insert the javascript
      # we're gonna use to collapse and expand the TOC
      html = <<EOF
<h1><span id="1"></span>#{@name}</h1>
#{@p_proc.__parse(@introduction, manual_section)}
<h1 id="toc-anchor">Table of Contents</h1>
#{Loki::Manual.script_for_toc_toggle}
<ul class="toc">
<li>#{Loki::Manual.standard_toggle_span(false)}<a href="#1"><span>1</span> Introduction</a></li>
EOF

      @sections.each do |section|
        html += __render_section_toc(section)
      end

      html += "</ul>\n"

      @sections.each do |section|
        html += __render_section(section, 0)
      end

      html
    end

    # This is to standardize the script generation here and for tests; there's
    # no point in hardcoding this in all of those heredocs especially
    # considering that this is not dynamically generated
    def self.standard_toggle_span(collapsed)
      display = collapsed ?  __right_arrow : '&nbsp;'
      html_class = collapsed ? __collapsed_class : __empty_class

      html = "<span class=\"#{html_class}\" style=\"float: left; width: 1em;"
      if (collapsed)
        html += " cursor: pointer;"
      end
      html += "\" onclick=\"toggleTOC(this);\">#{display}</span>"
    end

    def self.__empty_class
      'toc_empty'
    end

    def self.__collapsed_class
      'toc_collapsed'
    end

    def self.__expanded_class
      'toc_expanded'
    end

    def self.__right_arrow
      '&#9658;'
      '&#9656;'
    end

    def self.__down_arrow
      '&#9650;'
      '&#9662;'
    end

    def self.script_for_toc_toggle
      html = <<EOF
<script type="text/javascript">
function toggleTOC(elem) {
  var html_class = elem.className;
  var children = elem.parentNode.childNodes;
  if (html_class == '#{__collapsed_class}') {
    elem.className = '#{__expanded_class}';
    children[3].style.display = 'block';
    elem.innerHTML = '#{__down_arrow}'
  } else if (html_class == '#{__expanded_class}') {
    elem.className = '#{__collapsed_class}';
    children[3].style.display = 'none';
    elem.innerHTML = '#{__right_arrow}'
  }
}
</script>
EOF
    end

    def __render_section_toc(section)
      html = "<li>#{Loki::Manual.standard_toggle_span(section.length > 3)}"
      html += "<a href=\"##{section[1]}\">"
      html += "<span>#{section[1]}</span> #{section[0]}</a>"
      if (section.length > 3)
        html += "\n<ul style=\"display: none;\">\n"
        section[3..-1].each do |subsec|
          html += __render_section_toc(subsec)
        end
        html += "</ul>\n"
      end
      html += "</li>\n"

      html
    end

    def __render_section(section, depth)
      manual_section = "#{@page.__source_path} manual section " +
        "#{section[1]} #{section[0]}"

      html = "<h#{depth+2}><a href=\"#toc-anchor\">"
      html += "<span id=\"#{section[1]}\">#{section[1]}</span>"
      html += " #{section[0]}</a></h#{depth+2}>\n"
      html += @p_proc.__parse(section[2], manual_section) + "\n"
      if (section.length > 3)
        section[3..-1].each do |subsec|
          html += __render_section(subsec, depth + 1)
        end
      end

      html
    end
  end
end
