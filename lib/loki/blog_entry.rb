require 'loki/view'

class Loki
  class BlogEntry < View
    # List of metadata values that can be set, along with types for validation;
    # these are also used by the MetadataProcessor class
    META_SYMBOLS = Loki::View::META_SYMBOLS + %i(description)
    META_TYPES = Loki::View::META_TYPES + %i(string)

    META_SYMBOLS.each do |attr|
      self.send(:attr_accessor, attr)
    end

    def initialize(blog, source_root, destination_root, file)
      @blog = blog
      @file = file
      super(source_root, destination_root, [])
    end

    def __date_sidebar
      @blog.__date_sidebar(self)
    end

    def __tag_sidebar
      @blog.__tag_sidebar(self)
    end

    def __tag_list
      t_list = []
      if (tags)
        tags.sort.each do |tag|
          if (@blog.tag_pages)
            pp = Loki::PageProcessor.new(self)
            path = pp.__make_relative_path("blog/tags/#{URI.encode(tag)}.html",
              __destination_path)
            t_list.push("<a href=\"#{path}\">#{tag}</a>")
          else
            t_list.push("#{tag}")
          end
        end
      end
      t_list.join(', ')
    end

    def __newest(text)
      @blog.__newest(self, text)
    end

    def __previous(text)
      @blog.__previous(self, text)
    end

    def __next(text)
      @blog.__next(self, text)
    end

    def __oldest(text)
      @blog.__oldest(self, text)
    end

    # Unlike pages, these values are universal and are defined in the "parent"
    # blog object
    def template
      @blog.entry_template
    end

    def css
      @blog.css
    end

    def javascript
      @blog.javascript
    end

    def favicon
      @blog.favicon
    end

    def head
      @blog.head
    end

    # Internal functions use '__' to avoid collisions with possible user-defined
    # data and such, though in a pinch users COULD access if they understood the
    # internals sufficiently. Not worth the bother to prevent, really, this is
    # just to avoid accidents.
    def __source_path
      File.join(__source_root, @file)
    end

    def __destination_path
      File.join(__destination_root, 'blog', File.basename(@file)) + ".html"
    end

    def __destination_file
      File.join('blog', File.basename(@file)) + ".html"
    end
  end
end
