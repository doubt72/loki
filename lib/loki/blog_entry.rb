require 'loki/view'

class Loki
  class BlogEntry < View
    # List of metadata values that can be set, along with types for validation;
    # these are also used by the MetadataProcessor class
    META_SYMBOLS = Loki::View::META_SYMBOLS + %i(date description)
    META_TYPES = Loki::View::META_TYPES + %i(string string)

    META_SYMBOLS.each do |attr|
      self.send(:attr_accessor, attr)
    end

    def initialize(blog, source_root, destination_root, file)
      @blog = blog
      @file = file
      super(source_root, destination_root, [])
    end

    def date_sidebar
      @blog.date_sidebar(self)
    end

    def tags_sidebar
      @blog.tags_sidebar(self)
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