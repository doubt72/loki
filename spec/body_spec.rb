require 'spec_helper'

describe "Loki::Body" do
  context "link_abs" do
    it "link_abs returns absolute link" do
      url = '<a href="url">text</a>'
      expect(Loki::Body.link_abs("url", "text")).to eq(url)
    end

    it "link_abs with option id" do
      url = '<a href="url" id="id">text</a>'
      expect(Loki::Body.link_abs("url", "text", {id: "id"})).to eq(url)
    end

    it "link_abs with option class" do
      url = '<a href="url" class="class">text</a>'
      expect(Loki::Body.link_abs("url", "text", {class: "class"})).to eq(url)
    end

    it "link_abs with option style" do
      url = '<a href="url" style="style: style;">text</a>'
      expect(Loki::Body.link_abs("url", "text",
                                 {style: "style: style;"})).to eq(url)
    end

    it "link_abs with multiple options" do
      url = '<a href="url" id="id" class="class">text</a>'
      expect(Loki::Body.link_abs("url", "text",
                                 {id: "id", class: "class"})).to eq(url)
    end
  end # context "link_abs"

  context "eval" do
    it "evaluates simple directive" do
      data = 'link_abs("url", "text")'
      html = '<a href="url">text</a>'

      expect(Loki::Body.eval(data)).to eq(html)
    end

    it "handles bad directive" do
      data = 'noyo'
      msg = "Error processing page: invalid directive 'noyo'\n\n"

      expect {
        Loki::Body.eval(data)
      }.to raise_error(StandardError, msg)
    end

    it "handles syntax error" do
      data = 'link_abs('
      msg = /Error processing page.*syntax error/m

      expect {
        Loki::Body.eval(data)
      }.to raise_error(StandardError, msg)
    end
  end # context "eval"

  context "parse" do
    it "parses simple body" do
      body = "simple source\n"
      html = "simple source\n"

      expect(Loki::Body.parse(body)).to eq(html)
    end

    it "handles bracket escape" do
      body = "simple {{source}\n"
      html = "simple {source}\n"

      expect(Loki::Body.parse(body)).to eq(html)
    end

    it "evaluates simple directive" do
      body = 'simple {link_abs("url", "text")}'
      html = 'simple <a href="url">text</a>'

      expect(Loki::Body.parse(body)).to eq(html)
    end

    it "handles syntax error" do
      body = 'simple source {link_abs(}'
      msg = /Error processing page.*syntax error/m

      expect {
        Loki::Body.parse(body)
      }.to raise_error(StandardError, msg)
    end

    it "handles unbalanced directive" do
      body = 'simple source {link_abs'
      msg = "Error processing page: " +
        "unexpected end-of-file; no matching '}'\n\n"

      expect {
        Loki::Body.parse(body)
      }.to raise_error(StandardError, msg)
    end

    it "handles multi-line directive" do
      body = "simple {link_abs('url',\n'text')}"
      html = 'simple <a href="url">text</a>'

      expect(Loki::Body.parse(body)).to eq(html)
    end
  end # context "parse"

  context "generate" do
    let(:page) { Loki::Page.new("a", "b", ["view"]) }
    let(:engine) { Loki::Engine.new }

    before(:each) do
      allow(page).to receive(:load)

      engine.add(page)
    end

    it "handles a simple body" do
      page.body = "simple source\n"
      html = "<html>\n<body>\nsimple source\n</body>\n</html>\n"

      Loki::Body.generate(page, engine)
      expect(page.html).to eq(html)
    end

    it "handles a template" do
      allow(Loki::Utilities).to receive(:load_component).
        with("a", "template").and_return("<b>{body}</b>")

      page.template = "template"
      page.body = "simple source\n"
      html = "<html>\n<body>\n<b>simple source\n</b></body>\n</html>\n"

      Loki::Body.generate(page, engine)
      expect(page.html).to eq(html)
    end

    it "handles body include when not template" do
      page.body = "simple {body}\n"
      msg = "Error processing page: " +
        "attempt to include body outside of template\n\n"

      expect {
        Loki::Body.generate(page, engine)
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

      Loki::Body.generate(page, engine)
      expect(page.html).to eq(html)
    end
  end # context "generate"
end # describe "Loki::Body
