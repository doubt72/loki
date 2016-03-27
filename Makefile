all: bundle rspec build install

bundle:
	bundle install

rspec:
	rspec

build:
	gem build loki.gemspec

install:
	gem install loki-*.gem

clean:
	gem uninstall loki -a -x
	rm loki-*.gem
