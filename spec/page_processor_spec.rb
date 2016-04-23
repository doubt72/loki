require 'spec_helper'

# For injecting test values into the class
class Loki::PageProcessor
  attr_writer :parse_path, :parse_line
end

describe "Loki::PageProcessor" do
  let(:page) { Loki::Page.new('a', 'b', ['page']) }
  let(:p_proc) { Loki::PageProcessor.new(page) }
  let(:site) { Loki::Site.new }

  before(:each) do
    allow(page).to receive(:__site).and_return(site)
  end

  # Loki::PageProcessor.body doesn't get its own tests; it's much easier to
  # test with a bit more context and so is implicitly tested in the
  # Loki::PageProcessor.process tests below

  context "include" do
    it "returns parsed contents" do
      allow(Loki::Utils).to receive(:load_component).
        with("a", "partial").and_return("simple source")

      expect {
        expect(p_proc.include("partial")).to eq("simple source")
      }.to output("- including partial: partial\n").to_stdout
    end

    it "can be nested" do
      include = "simple source {include('second')}"
      include_second = "second"

      allow(Loki::Utils).to receive(:load_component).
        with("a", "partial").and_return(include)
      allow(Loki::Utils).to receive(:load_component).
        with("a", "second").and_return(include_second)

      expect {
        expect(p_proc.include("partial")).
        to eq("simple source second")
      }.to output("- including partial: partial\n" +
                  "- including partial: second\n").to_stdout
    end
  end # context "include"

  context "link_abs" do
    it "returns absolute link" do
      url = '<a href="url">text</a>'
      expect(p_proc.link_abs("url", "text")).to eq(url)
    end

    it "with option id" do
      url = '<a href="url" id="id">text</a>'
      expect(p_proc.link_abs("url", "text", {id: "id"})).to eq(url)
    end

    it "with option class" do
      url = '<a href="url" class="class">text</a>'
      expect(p_proc.link_abs("url", "text", {class: "class"})).to eq(url)
    end

    it "with option style" do
      url = '<a href="url" style="style: style;">text</a>'
      expect(p_proc.link_abs("url", "text",
        {style: "style: style;"})).to eq(url)
    end

    it "with multiple options" do
      url = '<a href="url" id="id" class="class">text</a>'
      expect(p_proc.link_abs("url", "text",
        {id: "id", class: "class"})).to eq(url)
    end
  end # context "link_abs"

  context "link" do
    it "returns link" do
      allow(site).to receive(:__lookup_path).with("a", "b", "id").
        and_return("views/id.html")

      url = '<a href="views/id.html">text</a>'
      expect(p_proc.link("id", "text")).to eq(url)
    end

    it "with option style" do
      allow(site).to receive(:__lookup_path).with("a", "b", "id").
        and_return("views/id.html")

      url = '<a href="views/id.html" style="style: style;">text</a>'
      expect(p_proc.link("id", "text", {style: "style: style;"})).to eq(url)
    end

    it "with multiple options" do
      allow(site).to receive(:__lookup_path).with("a", "b", "id").
        and_return("views/id.html")

      url = '<a href="views/id.html" id="id" class="class">text</a>'
      expect(p_proc.link("id", "text", {id: "id", class: "class"})).to eq(url)
    end

    it "copies asset" do
      allow(File).to receive(:exists?).with("a/assets/x.png").and_return(true)
      allow(Loki::Utils).to receive(:copy_asset).with("a", "b", "x.png")

      url = '<a href="assets/x.png">text</a>'
      expect(p_proc.link("x.png", "text")).to eq(url)
    end

    it "handles :append option" do
      allow(site).to receive(:__lookup_path).with("a", "b", "id").
        and_return("views/id.html")

      url = '<a href="views/id.html#top">text</a>'
      expect(p_proc.link("id", "text", {append: "#top"})).to eq(url)
    end

    it "handles :self_class option when self" do
      allow(site).to receive(:__lookup_path).with("a", "b", "id").
        and_return("views/id.html")

      p_proc.page.id = "id"

      url = '<a href="views/id.html" class="self">text</a>'
      expect(p_proc.link("id", "text", {self_class: "self"})).to eq(url)
    end

    it "handles :self_class option when not self" do
      allow(site).to receive(:__lookup_path).with("a", "b", "id").
        and_return("views/id.html")

      p_proc.page.id = "id2"

      url = '<a href="views/id.html">text</a>'
      expect(p_proc.link("id", "text", {self_class: "self"})).to eq(url)
    end

    it "handles combining :self_class and :class options" do
      allow(site).to receive(:__lookup_path).with("a", "b", "id").
        and_return("views/id.html")

      p_proc.page.id = "id"

      url = '<a href="views/id.html" class="self other">text</a>'
      expect(p_proc.link("id", "text",
        {self_class: "self", class: "other"})).to eq(url)
    end
  end # context "link"

  context "image" do
    before(:each) do
      allow(Loki::Utils).to receive(:copy_asset).with("a", "b", "x.png")
    end

    it "returns img" do
      img = '<img src="assets/x.png" />'
      expect(p_proc.image("x.png")).to eq(img)
    end

    it "with alt text" do
      img = '<img src="assets/x.png" alt="text" />'
      expect(p_proc.image("x.png", {alt: "text"})).to eq(img)
    end

    it "with option style" do
      img = '<img src="assets/x.png" style="style: style;" />'
      expect(p_proc.image("x.png", {style: "style: style;"})).to eq(img)
    end

    it "with multiple options" do
      img = '<img src="assets/x.png" id="id" class="class" />'
      expect(p_proc.image("x.png", {id: "id", class: "class"})).to eq(img)
    end

    it "handles relative path" do
      expect(p_proc.page).to receive(:__destination_path).
        and_return("a/dir/view.html")

      img = '<img src="../assets/x.png" />'
      expect(p_proc.image("x.png")).to eq(img)
    end
  end # context "image"

  context "table" do
    before(:each) do
      allow(Loki::Utils).to receive(:copy_asset).with("a", "b", "x.png")
    end

    it "returns a table" do
      html = <<EOF
<table>
  <tr>
    <td>a</td>
    <td>b</td>
  </tr>
  <tr>
    <td>c</td>
    <td>d</td>
  </tr>
</table>
EOF
      data = [["a", "b"], ["c", "d"]]
      expect(p_proc.table(data)).to eq(html)
    end

    it "handles options" do
      html = <<EOF
<table id="id" class="class">
  <tr>
    <td>a</td>
    <td>b</td>
  </tr>
  <tr>
    <td>c</td>
    <td>d</td>
  </tr>
</table>
EOF
      data = [["a", "b"], ["c", "d"]]
      expect(p_proc.table(data, {id: "id", class: "class"})).to eq(html)
    end

    it "handles invalid data" do
      data = "foo"
      msg = /table data must be an array/m

      expect {
        p_proc.table(data)
      }.to raise_error(StandardError, msg)
    end

    it "handles invalid row" do
      data = [["a", "b"], "c"]
      msg = /rows of table data must all be arrays/m

      expect {
        p_proc.table(data)
      }.to raise_error(StandardError, msg)
    end
  end

  context "__eval" do
    it "evaluates simple directive" do
      data = 'link_abs("url", "text")'
      html = '<a href="url">text</a>'

      expect(p_proc.__eval(data)).to eq(html)
    end

    it "handles bad directive" do
      data = 'noyo'
      p_proc.parse_line = 7
      p_proc.parse_path = 'path'

      msg = /Error on line 7 of file path.*invalid directive 'noyo'/m

      expect {
        p_proc.__eval(data)
      }.to raise_error(StandardError, msg)
    end

    it "handles syntax error" do
      data = 'link_abs('
      p_proc.parse_line = 7
      p_proc.parse_path = 'path'

      msg = /Error on line 7 of file path.*syntax error/m

      expect {
        p_proc.__eval(data)
      }.to raise_error(StandardError, msg)
    end
  end # context "__eval"

  context "__parse" do
    it "parses simple body" do
      body = "simple source\n"
      html = "simple source\n"

      expect(p_proc.__parse(body, "path")).to eq(html)
    end

    it "handles bracket escape" do
      body = "simple {{source}\n"
      html = "simple {source}\n"

      expect(p_proc.__parse(body, "path")).to eq(html)
    end

    it "handles double bracket escape" do
      body = "simple {{{{source}}\n"
      html = "simple {{source}}\n"

      expect(p_proc.__parse(body, "path")).to eq(html)
    end

    it "handles bracket escape inside context" do
      body = "simple { {foo: \"bar\"}} }\n"
      html = "simple {:foo=>\"bar\"}\n"

      expect(p_proc.__parse(body, "path")).to eq(html)
    end

    it "handles double bracket escape inside context" do
      body = "simple { {all: {foo: \"bar\"}}}} }\n"
      html = "simple {:all=>{:foo=>\"bar\"}}\n"

      expect(p_proc.__parse(body, "path")).to eq(html)
    end

    it "evaluates simple directive" do
      body = 'simple {link_abs("url", "text")}'
      html = 'simple <a href="url">text</a>'

      expect(p_proc.__parse(body, "path")).to eq(html)
    end

    it "handles syntax error" do
      body = 'simple source {link_abs(}'
      msg = /Error on line 1 of file path.*syntax error/m

      expect {
        p_proc.__parse(body, "path")
      }.to raise_error(StandardError, msg)
    end

    it "handles unbalanced directive" do
      body = 'simple source {link_abs'
      msg = "Error on line 1 of file path:\n" +
        "unexpected end-of-file; no matching '}'\n\n"

      expect {
        p_proc.__parse(body, "path")
      }.to raise_error(StandardError, msg)
    end

    it "handles multi-line directive" do
      body = "simple {link_abs('url',\n'text')}"
      html = 'simple <a href="url">text</a>'

      expect(p_proc.__parse(body, "path")).to eq(html)
    end
  end # context "__parse"

  context "__process" do
    let(:page) { Loki::Page.new("a", "b", ["view"]) }
    let(:site) { Loki::Site.new }

    before(:each) do
      allow(page).to receive(:load)

      site.__add_page(page)
    end

    it "handles a simple body" do
      page.__body = "simple source\n"
      html = "<html>\n<body>\nsimple source\n</body>\n</html>\n"

      p_proc.__process
      expect(page.__html).to eq(html)
    end

    it "handles a template" do
      allow(Loki::Utils).to receive(:load_component).
        with("a", "template").and_return("<b>{body}</b>")

      page.template = "template"
      page.__body = "simple source\n"
      html = "<html>\n<body>\n<b>simple source\n</b></body>\n</html>\n"

      expect {
        p_proc.__process
      }.to output("- using template: template\n").to_stdout
      expect(page.__html).to eq(html)
    end

    it "handles error in template" do
      allow(Loki::Utils).to receive(:load_component).
        with("a", "template").and_return("<b>\n\n{foo}</b>")

      page.template = "template"
      page.__body = "simple source\n"

      msg = /^Error.*line 3.*invalid directive 'foo'.*context.*\{foo\}/m

      expect {
        expect {
          p_proc.__process
        }.to raise_error(StandardError, msg)
      }.to output("- using template: template\n").to_stdout
    end

    it "handles body include when not template" do
      page.__body = "simple {body}\n"
      msg = /^Error.*line 1.*attempt to include body outside of template/m

      expect {
        p_proc.__process
      }.to raise_error(StandardError, msg)
    end

    it "handles headers" do
      allow(Loki::Utils).to receive(:copy_asset).with("a", "b", "css")
      allow(Loki::Utils).to receive(:copy_asset).with("a", "b", "js")
      allow(Loki::Utils).to receive(:copy_asset).with("a", "b", "js/js")
      allow(Loki::Utils).to receive(:copy_asset).
        with("a", "b", "favicon32.png")
      allow(Loki::Utils).to receive(:copy_asset).
        with("a", "b","favicon152.png")

      page.__body = "simple source\n"
      page.title = "title"
      page.css = ["css"]
      page.javascript = ["js", "js/js"]
      page.favicon = [[32, "icon", "favicon32.png"],
        [152, "apple-touch-icon", "favicon152.png"]]
      html = <<EOF
<html>
<head>
  <title>title</title>
  <link rel="stylesheet" href="assets/css" type="text/css" />
  <script src="assets/js" type="text/javascript"></script>
  <script src="assets/js/js" type="text/javascript"></script>
  <link rel="icon" type="image/png" href="assets/favicon32.png" sizes="32x32" />
  <link rel="apple-touch-icon" type="image/png" href="assets/favicon152.png" sizes="152x152" />
</head>
<body>
simple source
</body>
</html>
EOF

      p_proc.__process
      expect(page.__html).to eq(html)
    end

    it "handles relative headers" do
      allow(page).to receive(:__destination_path).and_return("b/dir/view.html")

      allow(Loki::Utils).to receive(:copy_asset).with("a", "b", "css")
      allow(Loki::Utils).to receive(:copy_asset).with("a", "b", "js")
      allow(Loki::Utils).to receive(:copy_asset).with("a", "b", "js/js")

      page.__body = "simple source\n"
      page.title = "title"
      page.css = ["css"]
      page.javascript = ["js", "js/js"]
      html = <<EOF
<html>
<head>
  <title>title</title>
  <link rel="stylesheet" href="../assets/css" type="text/css" />
  <script src="../assets/js" type="text/javascript"></script>
  <script src="../assets/js/js" type="text/javascript"></script>
</head>
<body>
simple source
</body>
</html>
EOF

      p_proc.__process
      expect(page.__html).to eq(html)
    end

    it "handles arbitrary head data" do
      allow(page).to receive(:__destination_path).and_return("b/dir/view.html")

      page.__body = "simple source\n"
      page.head = "foo\n"
      html = <<EOF
<html>
<head>
foo
</head>
<body>
simple source
</body>
</html>
EOF

      p_proc.__process
      expect(page.__html).to eq(html)
    end
  end # context "__process"

  context "__make_relative_path" do
    it "handles top same" do
      path = "page.html"
      here = "dest/page.html"

      expect(p_proc.__make_relative_path(path, here)).to eq("page.html")
    end

    it "handles deep same" do
      path = "dir/dir/dir/page.html"
      here = "dest/dir/dir/dir/page.html"

      expect(p_proc.__make_relative_path(path, here)).to eq("page.html")
    end

    it "handles top different" do
      path = "image.png"
      here = "dest/page.html"

      expect(p_proc.__make_relative_path(path, here)).to eq("image.png")
    end

    it "handles deep different" do
      path = "dir/dir/dir/image.png"
      here = "dest/dir/dir/dir/page.html"

      expect(p_proc.__make_relative_path(path, here)).to eq("image.png")
    end

    it "handles all different" do
      path = "foo/foo/foo/image.png"
      here = "dest/dir/dir/dir/page.html"

      expect(p_proc.__make_relative_path(path, here)).
        to eq("../../../foo/foo/foo/image.png")
    end

    it "handles here deeper" do
      path = "dir/dir/image.png"
      here = "dest/dir/dir/dir/page.html"

      expect(p_proc.__make_relative_path(path, here)).to eq("../image.png")
    end

    it "handles path deeper" do
      path = "dir/dir/dir/image.png"
      here = "dest/dir/dir/page.html"

      expect(p_proc.__make_relative_path(path, here)).to eq("dir/image.png")
    end

    it "handles here deep" do
      path = "image.png"
      here = "dest/dir/dir/dir/page.html"

      expect(p_proc.__make_relative_path(path, here)).
        to eq("../../../image.png")
    end

    it "handles path deep" do
      path = "dir/dir/dir/image.png"
      here = "dest/page.html"

      expect(p_proc.__make_relative_path(path, here)).
        to eq("dir/dir/dir/image.png")
    end
  end # context "__make_relative_path"
end # describe "Loki::PageProcessor
