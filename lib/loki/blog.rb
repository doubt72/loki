class Loki
  class Blog
    # List of metadata values that can be set, along with types for validation;
    # these are also used by the MetadataProcessor class
    META_SYMBOLS = %i(main_title main_template css javascript favicon head
      directory tag_pages generate_rss entry_template main_date_format
      description site_link)
    META_TYPES = %i(string string string_array string_array favicon_array string
      string boolean boolean string string string string)

    META_SYMBOLS.each do |attr|
      self.send(:attr_accessor, attr)
    end

    def initialize(site)
      @site = site
      @entries = []
    end

    # Internal functions use '__' to avoid collisions with possible user-defined
    # data and such, though in a pinch users COULD access if they understood the
    # internals sufficiently. Not worth the bother to prevent, really, this is
    # just to avoid accidents.
    def __load_entries(source_path, destination_path)
      if (directory.nil?)
        Loki::Utils.error("Must supply a directory with blog entries when using blog_config")
      end

      source_dir = File.join(source_path, directory)

      Dir.entries(source_dir).each do |name|
        path = File.join(source_dir, name)
        if (!File.directory?(path))
          entry = Loki::BlogEntry.new(self, source_path, destination_path,
            File.join(directory, name))
          entry.__load(@site)
          if (entry.id)
            @site.__check_and_add_id(entry.id, :blog_entry)
          end
          @entries.push(entry)
        end
      end

      __sort_entries

      __create_main_pages(source_path, destination_path)

      if (tag_pages)
        __build_tag_pages(source_path, destination_path)
      end

      if (generate_rss)
        __build_rss(File.join(destination_path, 'blog', 'rss.xml'))
      end
    end

    def __sort_entries
      @entries.sort! do |a, b|
        Time.parse(a.date) <=> Time.parse(b.date)
      end
    end

    def __create_main_pages(source_path, destination_path)
      page = Loki::Page.new(source_path, destination_path, ['blog', 'index'])
      page.id = "blog"
      page.title = main_title
      page.template = main_template
      page.css = css
      page.javascript = javascript
      page.favicon = favicon
      page.head = head
      if (@entries.length > 0)
        page.__body = ""
        @entries.each do |entry|
          if (!entry.id)
            Loki::Utils.error("All blog entries must have an id")
          end
          if (!entry.title)
            Loki::Utils.error("All blog entries must have a title")
          end
          if (!entry.date)
            Loki::Utils.error("All blog entries must have a date")
          end
          date = Time.parse(entry.date)
          if (main_date_format)
            date = date.strftime(main_date_format)
          else
            date = date.strftime("%Y-%m-%d %H:%M")
          end
          page.__body += "<p>{ link(\"#{entry.id}\", \"#{entry.title}\") } " +
            "<span class=\"blog-date\">[#{date}]</span></p>\n"
        end
      else
        page.__body = "No blog entries yet."
      end
      page.__load_site(@site)

      @site.__add_page(page)
    end

    def __build_entries
      @entries.each do |entry|
        entry.__build
      end
    end

    def __build_rss(path)
      puts "building rss ->"

      data = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"
      data += "<rss version=\"2.0\">\n"
      data += "<channel>\n"
      if (!main_title)
        Loki::Utils.error("Must supply main_title when generating RSS")
      end
      data += "  <title>#{main_title}</title>\n"
      if (!description)
        Loki::Utils.error("Must supply description when generating RSS")
      end
      data += "  <description>#{description}</description>\n"
      if (!site_link)
        Loki::Utils.error("Must supply site_link when generating RSS")
      end
      data += "  <link>#{site_link}</link>\n"
      data += "  <lastBuildDate>#{Time.now.to_s}</lastBuildDate>\n"
      @entries.each do |entry|
        data += "  <item>\n"
        data += "    <title>#{entry.title}</title>\n"
        if (!main_title)
          Loki::Utils.error("Must supply descriptions for entries when generating RSS")
        end
        data += "    <description>#{entry.description}</description>\n"
        data += "    <link>#{site_link + '/' + entry.__destination_file}</link>\n"
        data += "  </item>\n"
      end
      data += "</channel>\n"
      data += "</rss>\n"

      dir = File.dirname(path)
      FileUtils.mkdir_p(dir)
      puts "- writing: #{path}"
      File.write(path, data)

      puts ""
    end

    def __build_tag_pages(source_path, destination_path)
      tags = __all_tags
      tags.each_key do |tag|
        page = Loki::Page.new(source_path, destination_path,
          ['blog', 'tags', tag])
        page.id = "blog-#{tag}"
        page.title = "#{tag} tag"
        page.template = main_template
        page.css = css
        page.javascript = javascript
        page.favicon = favicon
        page.head = head
        page.__body = "<span class=\"blog-filter\">" +
          "Currently filtering on: <em>#{tag}</em></span>"

        refs = @site.__pages_with_tag(tag)
        refs.each do |ref|
          if (ref.title)
            page.__body += "<p>{ link(\"#{ref.id}\", \"#{ref.title}\") } " +
            "<span class=\"blog-date\">[main site]</span></p>\n"
          end
        end

        @entries.each do |entry|
          date = Time.parse(entry.date)
          if (main_date_format)
            date = date.strftime(main_date_format)
          else
            date = date.strftime("%Y-%m-%d %H:%M")
          end
          page.__body += "<p>{ link(\"#{entry.id}\", \"#{entry.title}\") } " +
          "<span class=\"blog-date\">[#{date}]</span></p>\n"
        end

        page.__load_site(@site)

        @site.__add_page(page)
      end
    end

    def __lookup_path(source, dest, id)
      # first look up
      @entries.each do |entry|
        if (entry.id && id == entry.id)
          return entry.__destination_file
        end
      end

      raise "couldn't link to '#{id}', no match found."
    end

    def __date_sidebar(page)
      rc = Loki::Blog.__script_for_date_toggle
      rc += "<div class=\"blog-date-sidebar\">\n" +
        "<ul style=\"list-style-type: none;\">\n"
      years = __make_date_buckets
      years.keys.reverse.each do |year|
        collapsed = false
        display = "block"
        if (year != Time.now.year)
          collapsed = true
          display = "none"
        end
        rc += "  <li style=\"clear: both;\">" +
          "#{Loki::Blog.__standard_toggle_span(collapsed)}<span>#{year}" +
          "</span>\n    <ul style=\"list-style-type: none; " +
          "display: #{display};\">\n"
        months = years[year]
        months.keys.reverse.each do |month|
          collapsed = false
          display = "block"
          if (year != Time.now.year || month != Time.now.month)
            collapsed = true
            display = "none"
          end
          rc += "      <li style=\"clear: both;\">" +
            "#{Loki::Blog.__standard_toggle_span(collapsed)}<span>" +
            "#{__month_names[month-1]}</span>\n" +
            "        <ul style=\"list-style-type: none; " +
            "display: #{display};\">\n"
          entries = months[month]
          entries.reverse.each do |entry|
            pp = Loki::PageProcessor.new(entry)
            name = File.basename(entry.__destination_path)
            path = pp.__make_relative_path(entry.__destination_file,
              page.__destination_path)
            rc += "          <li style=\"clear: both;\">" +
              "<a href=\"#{path}\">" +
              "#{entry.title}</a></li>\n"
          end
          rc += "        </ul>\n      </li>\n"
        end
        rc += "    </ul>\n  </li>\n"
      end
      rc += "</ul>\n</div>\n"
      rc
    end

    def __make_date_buckets
      years = {}
      @entries.each do |entry|
        date = Time.parse(entry.date)
        if (!years[date.year])
          years[date.year] = {}
        end
        year = years[date.year]
        if (!year[date.month])
          year[date.month] = []
        end
        month = year[date.month]
        month.push(entry)
      end
      years
    end

    def self.__standard_toggle_span(collapsed)
        display = collapsed ?  __right_arrow : __down_arrow
        html_class = collapsed ? __collapsed_class : __expanded_class

        html = "<span class=\"#{html_class}\" style=\"float: left; width: 1em;"
        html += " cursor: pointer;"
        html += "\" onclick=\"toggleDate(this);\">#{display}</span>"
    end

    def __month_names
      ["January", "February", "March", "April", "May", "June", "July",
        "August", "September", "October", "November", "December"]
    end

    def self.__collapsed_class
      'blog_date_collapsed'
    end

    def self.__expanded_class
      'blog_date_expanded'
    end

    def self.__right_arrow
      '&#9656;'
    end

    def self.__down_arrow
      '&#9662;'
    end

    def self.__script_for_date_toggle
      Loki::Utils.script_for_toggle("toggleDate", __collapsed_class,
        __expanded_class, __down_arrow, __right_arrow)
    end

    def __all_tags
      tags = @site.__tags
      @entries.each do |entry|
        if (entry.tags)
          entry.tags.each do |tag|
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

    def __tag_sidebar(page)
      rc = "<div class=\"blog-tag-sidebar\">\n<ul>\n"
      tags = __all_tags
      tags.keys.sort.each do |tag|
        count = tags[tag]
        if (tag_pages)
          pp = Loki::PageProcessor.new(page)
          path = pp.__make_relative_path("blog/tags/#{tag}.html",
            page.__destination_path)
          rc += "<li><a href=\"#{path}\">#{tag} (#{count})</a></li>\n"
        else
          rc += "<li>#{tag} (#{count})</li>"
        end
      end
      rc += "</ul>\n</div>\n"
      rc
    end
  end
end
