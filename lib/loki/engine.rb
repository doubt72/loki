class Loki
  class Engine
    def initialize
      @pages = []
    end

    # loads page on add
    def add(page)
      page.load

      @pages.push(page)
    end

    def eval_all
      @pages.each do |page|
        page.build(self)
      end
    end
  end
end
