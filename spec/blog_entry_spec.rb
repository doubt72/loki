require 'spec_helper'

class Loki::Blog
  attr_accessor :entries
end

describe "Loki::BlogEntry" do
  let(:site) { Loki::Site.new }
  let(:blog) { Loki::Blog.new(site) }
  let(:blog_entry) { Loki::BlogEntry.new(blog, "source/blog", "dest", "file") }

  before :each do
    blog.directory = "blog"
  end

  context "__load" do
    it "works" do
      allow(File).to receive(:read).with("source/blog/file").
        and_return("id \"id\"\n--\n--\nstuff\n")

      expect {
        blog_entry.__load(site)
      }.to output("loading source: source/blog/file\n").to_stdout

      expect(blog_entry.id).to eq("id")
      expect(blog_entry.__body).to eq("--\nstuff\n")
    end
  end # context "__load"

  context "__build" do
    it "works" do
      blog_entry.id = "id"
      blog_entry.__body = "one + one = {1 + 1}\n"

      html = <<EOF
<html>
<head>
  <meta charset="UTF-8" />
</head>
<body>
one + one = 2
</body>
</html>
EOF

      expect(FileUtils).to receive(:mkdir_p).with("dest/blog")
      expect(File).to receive(:write).with("dest/blog/file.html", html)

      expect {
        blog_entry.__build
      }.to output("page: source/blog/file ->\n" +
                  "- writing: dest/blog/file.html\n\n").to_stdout
    end
  end # context "__build"

  context "page access" do
    it "works" do
      allow(File).to receive(:read).with("source/blog/file").
        and_return("id \"id\"\n--\nstuff: {page.id}\n")

      html = <<EOF
<html>
<head>
  <meta charset="UTF-8" />
</head>
<body>
stuff: id
</body>
</html>
EOF

      expect {
        blog_entry.__load(site)
      }.to output("loading source: source/blog/file\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("dest/blog")
      expect(File).to receive(:write).with("dest/blog/file.html", html)

      expect {
        blog_entry.__build
      }.to output("page: source/blog/file ->\n" +
                  "- writing: dest/blog/file.html\n\n").to_stdout
    end

    it "handles custom metadata with set" do
      allow(File).to receive(:read).with("source/blog/file").
        and_return("id \"id\"\nset :key, \"value\"\nset \"foo\", \"bar\"" +
                   "\n--\nstuff: {page.key}\nalso: {page.foo}\n")

      html = <<EOF
<html>
<head>
  <meta charset="UTF-8" />
</head>
<body>
stuff: value
also: bar
</body>
</html>
EOF

      expect {
        blog_entry.__load(site)
      }.to output("loading source: source/blog/file\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("dest/blog")
      expect(File).to receive(:write).with("dest/blog/file.html", html)

      expect {
        blog_entry.__build
      }.to output("page: source/blog/file ->\n" +
                  "- writing: dest/blog/file.html\n\n").to_stdout
    end

    it "handles custom metadata with global" do
      allow(File).to receive(:read).with("source/blog/file").
        and_return("id \"id\"\nglobal :key, \"value\"\n" +
                   "global \"foo\", \"bar\"" +
                   "\n--\nstuff: {site.key}\nalso: {site.foo}\n")

      html = <<EOF
<html>
<head>
  <meta charset="UTF-8" />
</head>
<body>
stuff: value
also: bar
</body>
</html>
EOF

      expect {
        blog_entry.__load(site)
      }.to output("loading source: source/blog/file\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("dest/blog").twice
      expect(File).to receive(:write).with("dest/blog/file.html", html)

      page2 = Loki::BlogEntry.new(blog, "source/blog", "dest", "file2")

      allow(File).to receive(:read).with("source/blog/file2").
        and_return("id \"id2\"\n--\nstuff: {site.key}\nalso: {site.foo}\n")

      expect {
        page2.__load(site)
      }.to output("loading source: source/blog/file2\n").to_stdout

      expect(File).to receive(:write).with("dest/blog/file2.html", html)

      # Swap the order as a minimal test of ordering
      expect {
        page2.__build
      }.to output("page: source/blog/file2 ->\n" +
                  "- writing: dest/blog/file2.html\n\n").to_stdout

      expect {
        blog_entry.__build
      }.to output("page: source/blog/file ->\n" +
                  "- writing: dest/blog/file.html\n\n").to_stdout
    end

    it "can set value inside page" do
      allow(File).to receive(:read).with("source/blog/file").
        and_return("id \"id\"\n--\nstuff: " +
                   "{page.set :foo, \"bar\"\n\"stuff\"}\n" +
                   "also: {page.foo}\n")

      html = <<EOF
<html>
<head>
  <meta charset="UTF-8" />
</head>
<body>
stuff: stuff
also: bar
</body>
</html>
EOF

      expect {
        blog_entry.__load(site)
      }.to output("loading source: source/blog/file\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("dest/blog")
      expect(File).to receive(:write).with("dest/blog/file.html", html)

      expect {
        blog_entry.__build
      }.to output("page: source/blog/file ->\n" +
                  "- writing: dest/blog/file.html\n\n").to_stdout
    end
  end # context "page access"

  context "site access" do
    it "works" do
      allow(File).to receive(:read).with("source/blog/file").
        and_return("id \"id\"\n--\n{ site.set :foo, 'bar'; ''}stuff: " +
                   "{ site.foo }\n")

      html = <<EOF
<html>
<head>
  <meta charset="UTF-8" />
</head>
<body>
stuff: bar
</body>
</html>
EOF

      site.__add_page(blog_entry)
      expect {
        site.__load_pages
      }.to output("loading source: source/blog/file\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("dest/blog")
      expect(File).to receive(:write).with("dest/blog/file.html", html)

      expect {
        blog_entry.__build
      }.to output("page: source/blog/file ->\n" +
                  "- writing: dest/blog/file.html\n\n").to_stdout
    end
  end # context "site access"

  context "source and dest" do
    it "returns source file and dest paths" do
      expect(blog_entry.__source_path).to eq("source/blog/file")
      expect(blog_entry.__destination_path).to eq("dest/blog/file.html")
    end
  end # context "source and dest"

  context "date" do
    it "works" do
      blog_entry.date = '2016-01-01 12:00'
      processor = Loki::PageProcessor.new(blog_entry)
      expect(processor.date).to eq('2016-01-01 12:00')
    end

    it "handles formatting" do
      blog_entry.date = '2016-01-01 12:00'
      processor = Loki::PageProcessor.new(blog_entry)
      expect(processor.date('%d/%m/%Y %H:%M')).to eq('01/01/2016 12:00')
    end
  end # context "date"

  context "date_sidebar" do
    it "works" do
      blog_entry.date = '2015-01-01 12:00'
      blog.entries = [blog_entry]

      li = "<li style=\"clear: both;\"><span class=\"blog_date_expanded\" " +
        "style=\"float: left; width: 1em; cursor: pointer;\" " +
        "onclick=\"toggleDate(this);\">&#9662;</span>"
      li2 = ""
      html =<<EOF
<div class="blog-date-sidebar">
<ul style="list-style-type: none;">
  #{li}<span>2015</span>
    <ul style="list-style-type: none; display: block;">
      #{li}<span>January</span>
        <ul style="list-style-type: none; display: block;">
          <li style="clear: both;"><a href="file.html"></a></li>
        </ul>
      </li>
    </ul>
  </li>
</ul>
</div>
EOF
      html = Loki::Blog.__script_for_date_toggle + html

      processor = Loki::PageProcessor.new(blog_entry)
      expect(processor.date_sidebar).to eq(html)
    end

    it "collapses old " do
      blog_entry.date = '2016-01-01 12:00'
      blog_entry2 = Loki::BlogEntry.new(blog, "source/blog", "dest", "file")
      blog_entry2.date = '2015-01-01 12:00'
      blog.entries = [blog_entry2, blog_entry]

      c_li = "<li style=\"clear: both;\"><span class=\"blog_date_collapsed\" " +
        "style=\"float: left; width: 1em; cursor: pointer;\" " +
        "onclick=\"toggleDate(this);\">&#9656;</span>"
      e_li = "<li style=\"clear: both;\"><span class=\"blog_date_expanded\" " +
        "style=\"float: left; width: 1em; cursor: pointer;\" " +
        "onclick=\"toggleDate(this);\">&#9662;</span>"

      li2 = ""
      html =<<EOF
<div class="blog-date-sidebar">
<ul style="list-style-type: none;">
  #{e_li}<span>2016</span>
    <ul style="list-style-type: none; display: block;">
      #{e_li}<span>January</span>
        <ul style="list-style-type: none; display: block;">
          <li style="clear: both;"><a href="file.html"></a></li>
        </ul>
      </li>
    </ul>
  </li>
  #{c_li}<span>2015</span>
    <ul style="list-style-type: none; display: none;">
      #{c_li}<span>January</span>
        <ul style="list-style-type: none; display: none;">
          <li style="clear: both;"><a href="file.html"></a></li>
        </ul>
      </li>
    </ul>
  </li>
</ul>
</div>
EOF
      html = Loki::Blog.__script_for_date_toggle + html

      processor = Loki::PageProcessor.new(blog_entry)
      expect(processor.date_sidebar).to eq(html)
    end
  end # context "date"

  context "tag_sidebar" do
    it "works" do
      blog_entry.tags = ['foo', 'bar']

      blog_entry2 = Loki::BlogEntry.new(blog, "source/blog", "dest", "file2")
      blog_entry2.tags = ['foo']

      blog.entries = [blog_entry, blog_entry2]
      html =<<EOF
<div class="blog-tag-sidebar">
<ul>
<li>bar (1)</li>
<li>foo (2)</li>
</ul>
</div>
EOF

      processor = Loki::PageProcessor.new(blog_entry)
      expect(processor.tag_sidebar).to eq(html)
    end

    it "handles links and special characters" do
      blog.tag_pages = true
      blog_entry.tags = ['ふ〜', 'バル']
      blog.entries = [blog_entry]
      html =<<EOF
<div class="blog-tag-sidebar">
<ul>
<li><a href="tags/%E3%81%B5%E3%80%9C.html">ふ〜 (1)</a></li>
<li><a href="tags/%E3%83%90%E3%83%AB.html">バル (1)</a></li>
</ul>
</div>
EOF

      processor = Loki::PageProcessor.new(blog_entry)
      expect(processor.tag_sidebar).to eq(html)
    end
  end # context "date"

  context "rss_feed" do
    it "works" do
      processor = Loki::PageProcessor.new(blog_entry)
      expect(processor.rss_feed('feed')).to eq('<a href="rss.xml">feed</a>')
    end
  end # context "date"

  context "__validate_type" do
    it "handles bad type" do
      msg = "Internal error: undefined metadata type bar\n\n"
      blog_entry.id = "id"

      expect {
        blog_entry.__validate_type(:id, :bar)
      }.to raise_error(StandardError, msg)
    end
  end # context "__validate_type"
end # describe "Loki::BlogEntry"
