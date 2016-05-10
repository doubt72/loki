class Loki
  class Blog
    # List of metadata values that can be set, along with types for validation;
    # these are also used by the MetadataProcessor class
    META_SYMBOLS = %i(template css javascript favicon head directory tag_pages
      generate_rss)
    META_TYPES = %i(string string_array string_array favicon_array string string
      boolean boolean)

    META_SYMBOLS.each do |attr|
      self.send(:attr_accessor, attr)
    end

    def initialize()
    end

    # Internal functions use '__' to avoid collisions with possible user-defined
    # data and such, though in a pinch users COULD access if they understood the
    # internals sufficiently. Not worth the bother to prevent, really, this is
    # just to avoid accidents.
  end
end
