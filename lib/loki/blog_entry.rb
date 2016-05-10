require 'loki/view'

class Loki
  class BlogEntry < View
    # List of metadata values that can be set, along with types for validation;
    # these are also used by the MetadataProcessor class
    META_SYMBOLS = Loki::View::META_SYMBOLS + %i(date)
    META_TYPES = Loki::View::META_TYPES + %i(string)

    META_SYMBOLS.each do |attr|
      self.send(:attr_accessor, attr)
    end

    def initialize(source_root, destination_root, path_components)
      super(source_root, destination_root, path_components)
    end

    # Internal functions use '__' to avoid collisions with possible user-defined
    # data and such, though in a pinch users COULD access if they understood the
    # internals sufficiently. Not worth the bother to prevent, really, this is
    # just to avoid accidents.

    # TODO: anything here?
  end
end
