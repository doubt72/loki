require 'spec_helper'

# Set some stuff up
class Loki
  class Body
    def self.setup_for_tests
      @@current_page = Loki::Page.new("a", "b", "view")
      @@global_state = Loki::State.new
    end
  end
end

describe "Loki::Body" do
  # Loki::Body.body doesn't get its own tests; it's much easier to
  # test with a bit more context and so is implicitly tested in the
  # Loki::Body.generate tests below

  context "include" do
    before(:each) do
      Loki::Body.setup_for_tests
    end

    it "returns parsed contents" do
      allow(Loki::Utilities).to receive(:load_component).
        with("a", "partial").and_return("simple source")

      expect(Loki::Body.include("partial")).to eq("simple source")
    end

    it "can be nested" do
      include = "simple source {include('second')}"
      include_second = "second"

      allow(Loki::Utilities).to receive(:load_component).
        with("a", "partial").and_return(include)
      allow(Loki::Utilities).to receive(:load_component).
        with("a", "second").and_return(include_second)

      expect(Loki::Body.include("partial")).to eq("simple source second")
    end
  end # context "include"

  context "link_abs" do
    it "returns absolute link" do
      url = '<a href="url">text</a>'
      expect(Loki::Body.link_abs("url", "text")).to eq(url)
    end

    it "with option id" do
      url = '<a href="url" id="id">text</a>'
      expect(Loki::Body.link_abs("url", "text", {id: "id"})).to eq(url)
    end

    it "with option class" do
      url = '<a href="url" class="class">text</a>'
      expect(Loki::Body.link_abs("url", "text", {class: "class"})).to eq(url)
    end

    it "with option style" do
      url = '<a href="url" style="style: style;">text</a>'
      expect(Loki::Body.link_abs("url", "text",
                                 {style: "style: style;"})).to eq(url)
    end

    it "with multiple options" do
      url = '<a href="url" id="id" class="class">text</a>'
      expect(Loki::Body.link_abs("url", "text",
                                 {id: "id", class: "class"})).to eq(url)
    end
  end # context "link_abs"

  context "link" do
    let(:state) { Loki::Body.setup_for_tests }

    it "returns link" do
      allow(state).to receive(:lookup).with("a", "b", "id").
        and_return("views/id")

      url = '<a href="views/id">text</a>'
      expect(Loki::Body.link("id", "text")).to eq(url)
    end

    it "with option style" do
      allow(state).to receive(:lookup).with("a", "b", "id").
        and_return("views/id")

      url = '<a href="views/id" style="style: style;">text</a>'
      expect(Loki::Body.link("id", "text",
                             {style: "style: style;"})).to eq(url)
    end

    it "with multiple options" do
      allow(state).to receive(:lookup).with("a", "b", "id").
        and_return("views/id")

      url = '<a href="views/id" id="id" class="class">text</a>'
      expect(Loki::Body.link("id", "text",
                             {id: "id", class: "class"})).to eq(url)
    end

    it "copies asset" do
      allow(File).to receive(:exists?).with("a/assets/x.png").and_return(true)
      allow(Loki::Utilities).to receive(:copy_asset).with("a", "b", "x.png")

      url = '<a href="assets/x.png">text</a>'
      expect(Loki::Body.link("x.png", "text")).to eq(url)
    end
  end # context "link"

  context "image" do
    let(:state) { Loki::Body.setup_for_tests }

    before(:each) do
      allow(Loki::Utilities).to receive(:copy_asset).with("a", "b", "x.png")
    end

    it "returns absolute link" do
      img = '<img src="x.png" />'
      expect(Loki::Body.image("x.png")).to eq(img)
    end

    it "with option style" do
      img = '<img src="x.png" style="style: style;" />'
      expect(Loki::Body.image("x.png", {style: "style: style;"})).to eq(img)
    end

    it "with multiple options" do
      img = '<img src="x.png" id="id" class="class" />'
      expect(Loki::Body.image("x.png", {id: "id", class: "class"})).to eq(img)
    end
  end # context "image"

  context "eval" do
    it "evaluates simple directive" do
      data = 'link_abs("url", "text")'
      html = '<a href="url">text</a>'

      expect(Loki::Body.__eval(data)).to eq(html)
    end

    it "handles bad directive" do
      data = 'noyo'
      msg = "Error processing page: invalid directive 'noyo'\n\n"

      expect {
        Loki::Body.__eval(data)
      }.to raise_error(StandardError, msg)
    end

    it "handles syntax error" do
      data = 'link_abs('
      msg = /Error processing page.*syntax error/m

      expect {
        Loki::Body.__eval(data)
      }.to raise_error(StandardError, msg)
    end
  end # context "eval"

  context "parse" do
    it "parses simple body" do
      body = "simple source\n"
      html = "simple source\n"

      expect(Loki::Body.__parse(body)).to eq(html)
    end

    it "handles bracket escape" do
      body = "simple {{source}\n"
      html = "simple {source}\n"

      expect(Loki::Body.__parse(body)).to eq(html)
    end

    it "evaluates simple directive" do
      body = 'simple {link_abs("url", "text")}'
      html = 'simple <a href="url">text</a>'

      expect(Loki::Body.__parse(body)).to eq(html)
    end

    it "handles syntax error" do
      body = 'simple source {link_abs(}'
      msg = /Error processing page.*syntax error/m

      expect {
        Loki::Body.__parse(body)
      }.to raise_error(StandardError, msg)
    end

    it "handles unbalanced directive" do
      body = 'simple source {link_abs'
      msg = "Error processing page: " +
        "unexpected end-of-file; no matching '}'\n\n"

      expect {
        Loki::Body.__parse(body)
      }.to raise_error(StandardError, msg)
    end

    it "handles multi-line directive" do
      body = "simple {link_abs('url',\n'text')}"
      html = 'simple <a href="url">text</a>'

      expect(Loki::Body.__parse(body)).to eq(html)
    end
  end # context "parse"

  context "generate" do
    let(:page) { Loki::Page.new("a", "b", ["view"]) }
    let(:state) { Loki::State.new }

    before(:each) do
      allow(page).to receive(:load)

      state.add(page)
    end

    it "handles a simple body" do
      page.body = "simple source\n"
      html = "<html>\n<body>\nsimple source\n</body>\n</html>\n"

      Loki::Body.generate(page, state)
      expect(page.html).to eq(html)
    end

    it "handles a template" do
      allow(Loki::Utilities).to receive(:load_component).
        with("a", "template").and_return("<b>{body}</b>")

      page.template = "template"
      page.body = "simple source\n"
      html = "<html>\n<body>\n<b>simple source\n</b></body>\n</html>\n"

      Loki::Body.generate(page, state)
      expect(page.html).to eq(html)
    end

    it "handles body include when not template" do
      page.body = "simple {body}\n"
      msg = "Error processing page: " +
        "attempt to include body outside of template\n\n"

      expect {
        Loki::Body.generate(page, state)
      }.to raise_error(StandardError, msg)
    end

    it "handles headers" do
      allow(Loki::Utilities).to receive(:copy_asset).with("a", "b", "css")
      allow(Loki::Utilities).to receive(:copy_asset).with("a", "b", "js")
      allow(Loki::Utilities).to receive(:copy_asset).with("a", "b", "js/js")

      page.body = "simple source\n"
      page.title = "title"
      page.css = ["css"]
      page.javascript = ["js", "js/js"]
      html = <<EOF
<html>
<head>
  <title>title</title>
  <link rel="stylesheet" href="assets/css" type="text/css" />
  <script src="assets/js" type="text/javascript"></script>
  <script src="assets/js/js" type="text/javascript"></script>
</head>
<body>
simple source
</body>
</html>
EOF

      Loki::Body.generate(page, state)
      expect(page.html).to eq(html)
    end
  end # context "generate"
end # describe "Loki::Body
