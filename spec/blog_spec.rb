require 'spec_helper'

# For inspection
class Loki::Blog
  def entries
    @entries
  end
end

class Loki::Site
  def pages
    @pages
  end
end

describe "Loki::Blog" do
  let(:site) { Loki::Site.new }
  let(:blog) { Loki::Blog.new(site) }
  let(:body) { "id 'entry'\ntitle 'title'\ndate '2016-01-01'\n" +
    "description 'description'\ntags ['a', 'b']\n--\nentry\n" }

  context "__load_entries" do
    it "handles missing directory" do
      msg = "Must supply a directory with blog entries when using blog_config\n\n"

      expect {
        blog.__load_entries("source", "dest")
      }.to raise_error(StandardError, msg)
    end

    it "loads entries and handles entry metadata" do
      blog.directory = "blog"

      allow(Dir).to receive(:entries).with("source/blog").
        and_return([".", "..", "entry"])
      allow(File).to receive(:directory?).with("source/blog/.").and_return(true)
      allow(File).to receive(:directory?).with("source/blog/..").
        and_return(true)
      allow(File).to receive(:directory?).with("source/blog/entry").
        and_return(false)

      expect(File).to receive(:read).with("source/blog/entry").
        and_return(body)

      expect {
        blog.__load_entries("source", "dest")
      }.to output("loading source: source/blog/entry\n").to_stdout
      expect(blog.entries.first.id).to eq("entry")
    end

    it "handles duplicate ids" do
      blog.directory = "blog"
      foo_body = "id 'entry'\ndate '2016'\n--\nfoo\n"
      bar_body = "id 'entry'\ndate '2016'\n--\nbar\n"

      allow(Dir).to receive(:entries).with("source/blog").
        and_return([".", "..", "foo", "bar"])
      allow(File).to receive(:directory?).with("source/blog/.").and_return(true)
      allow(File).to receive(:directory?).with("source/blog/..").
        and_return(true)
      allow(File).to receive(:directory?).with("source/blog/foo").
        and_return(false)
      allow(File).to receive(:directory?).with("source/blog/bar").
        and_return(false)

      expect(File).to receive(:read).with("source/blog/foo").
        and_return(foo_body)
      expect(File).to receive(:read).with("source/blog/bar").
        and_return(bar_body)

      msg = "Error loading blog entry: duplicate id 'entry'\n\n"

      expect {
        expect {
          blog.__load_entries("source", "dest")
        }.to raise_error(StandardError, msg)
      }.to output("loading source: source/blog/foo\n" +
        "loading source: source/blog/bar\n").to_stdout
    end
  end # context "__load_entries"

  context "__build_entries" do
    it "builds entry" do
      blog.directory = "blog"
      html =<<EOF
<html>
<head>
  <meta charset="UTF-8" />
  <title>title</title>
</head>
<body>
entry
</body>
</html>
EOF

      allow(Dir).to receive(:entries).with("source/blog").
        and_return([".", "..", "entry"])
      allow(File).to receive(:directory?).with("source/blog/.").and_return(true)
      allow(File).to receive(:directory?).with("source/blog/..").
        and_return(true)
      allow(File).to receive(:directory?).with("source/blog/entry").
        and_return(false)

      expect(File).to receive(:read).with("source/blog/entry").
        and_return(body)

      expect {
        blog.__load_entries("source", "dest")
      }.to output("loading source: source/blog/entry\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("dest/blog")
      expect(File).to receive(:write).with("dest/blog/entry.html", html)

      expect {
        blog.__build_entries
      }.to output("page: source/blog/entry ->\n" +
                  "- writing: dest/blog/entry.html\n\n").to_stdout
    end

    it "builds tag pages if tag_pages set" do
      blog.directory = "blog"
      blog.tag_pages = true
      html = "<html>\n<head>\n  <title>title</title>\n</head>\n" +
        "<body>\nentry\n</body>\n</html>\n"

      allow(Dir).to receive(:entries).with("source/blog").
        and_return([".", "..", "entry", "entry2"])
      allow(File).to receive(:directory?).with("source/blog/.").and_return(true)
      allow(File).to receive(:directory?).with("source/blog/..").
        and_return(true)
      allow(File).to receive(:directory?).with("source/blog/entry").
        and_return(false)
      allow(File).to receive(:directory?).with("source/blog/entry2").
        and_return(false)

      expect(File).to receive(:read).with("source/blog/entry").
        and_return(body)

      body2 = "id 'entry2'\ntitle 'title2'\ndate '2016-01-02'\n" +
        "description 'description2'\ntags ['a']\n--\nentry\n"

      expect(File).to receive(:read).with("source/blog/entry2").
        and_return(body2)

      expect {
        blog.__load_entries("source", "dest")
      }.to output("loading source: source/blog/entry\n" +
                  "loading source: source/blog/entry2\n").to_stdout

      expect(site.pages.length).to eq(3)

      list = "<span class=\"blog-filter\">Currently filtering on: " +
        "<em>a</em></span>\n<p>{ link(\"entry2\", \"title2\") } " +
        "<span class=\"blog-date\">[2016-01-02 00:00]</span></p>\n" +
        "<p>{ link(\"entry\", \"title\") } " +
        "<span class=\"blog-date\">[2016-01-01 00:00]</span></p>\n"

      a = site.pages[1]
      expect(a.id).to eq("tag-a")
      expect(a.__body).to eq(list)

      list2 = "<span class=\"blog-filter\">Currently filtering on: " +
        "<em>b</em></span>\n<p>{ link(\"entry\", \"title\") } " +
        "<span class=\"blog-date\">[2016-01-01 00:00]</span></p>\n"

      b = site.pages[2]
      expect(b.id).to eq("tag-b")
      expect(b.__body).to eq(list2)
    end

    it "generates rss if generate_rss set" do
      blog.directory = "blog"
      blog.generate_rss = true
      blog.main_title = "main title"
      blog.description = "description"
      blog.site_link = "http://www.example.com"
      # Is this the worst thing ever?  Yeah, probably
      xml = %r{
        ^<\?xml\sversion="1.0"\sencoding="UTF-8"\s\?>\n
        <rss\sversion="2.0">\n
        <channel>\n
        \s\s<title>main\stitle<\/title>\n
        \s\s<description>description<\/description>\n
        \s\s<link>http:\/\/www.example.com<\/link>\n
        \s\s<lastBuildDate>\d\d\d\d-\d\d-\d\d\s\d\d:\d\d:\d\d\s.\d\d\d\d<\/lastBuildDate>\n
        \s\s<item>\n
        \s\s\s\s<title>title<\/title>\n
        \s\s\s\s<description>description<\/description>\n
        \s\s\s\s<link>http:\/\/www.example.com\/blog\/entry.html<\/link>\n
        \s\s\s\s<pubDate>\d\d\d\d-\d\d-\d\d\s\d\d:\d\d:\d\d\s.\d\d\d\d<\/pubDate>\n
        \s\s<\/item>\n
        <\/channel>\n
        <\/rss>\n$
      }xm

      allow(Dir).to receive(:entries).with("source/blog").
        and_return([".", "..", "entry"])
      allow(File).to receive(:directory?).with("source/blog/.").and_return(true)
      allow(File).to receive(:directory?).with("source/blog/..").
        and_return(true)
      allow(File).to receive(:directory?).with("source/blog/entry").
        and_return(false)

      expect(File).to receive(:read).with("source/blog/entry").
        and_return(body)

      expect(FileUtils).to receive(:mkdir_p).with("dest/blog")
      expect(File).to receive(:write).with("dest/blog/rss.xml", xml)

      expect {
        blog.__load_entries("source", "dest")
      }.to output("loading source: source/blog/entry\n" +
        "building rss ->\n- writing: dest/blog/rss.xml\n\n").to_stdout
    end

    it "creates main pages" do
      blog.directory = "blog"
      blog.main_title = "main title"
      blog.entries_per_page = 2
      html = []
      0.upto(2) do |x|
        html.push("<html>\n<head>\n  <title>title#{x}</title>\n</head>\n" +
          "<body>\nentry#{x}\n</body>\n</html>\n")
      end
      body = []
      0.upto(2) do |x|
        body.push("id 'entry#{x}'\ndate '2016-01-1#{x}'\ntitle 'title#{x}'\n" +
          "--\nentry#{x}\n")
      end

      allow(Dir).to receive(:entries).with("source/blog").
        and_return([".", "..", "entry1", "entry2", "entry3"])
      allow(File).to receive(:directory?).with("source/blog/.").and_return(true)
      allow(File).to receive(:directory?).with("source/blog/..").
        and_return(true)
      allow(File).to receive(:directory?).with("source/blog/entry1").
        and_return(false)
      allow(File).to receive(:directory?).with("source/blog/entry2").
        and_return(false)
      allow(File).to receive(:directory?).with("source/blog/entry3").
        and_return(false)

      expect(File).to receive(:read).with("source/blog/entry1").
        and_return(body[0])
      expect(File).to receive(:read).with("source/blog/entry2").
        and_return(body[1])
      expect(File).to receive(:read).with("source/blog/entry3").
        and_return(body[2])

      expect {
        blog.__load_entries("source", "dest")
      }.to output("loading source: source/blog/entry1\nloading source: " +
        "source/blog/entry2\nloading source: source/blog/entry3\n").to_stdout

      expect(site.pages.length).to eq(2)

      list = <<EOF
<div class="blog-entry-list">
<p>{ link("entry2", "title2") } <span class="blog-date">[2016-01-12 00:00]</span></p>
<p>{ link("entry1", "title1") } <span class="blog-date">[2016-01-11 00:00]</span></p>
</div>
<div>&nbsp;</div>
<span class="next-blog-page"><a href="page2.html">next page [2]</a></span>
EOF

      first = site.pages.first
      expect(first.id).to eq("blog")
      expect(first.__body).to eq(list)

      list2 = <<EOF
<div class="blog-entry-list">
<p>{ link("entry0", "title0") } <span class="blog-date">[2016-01-10 00:00]</span></p>
</div>
<div>&nbsp;</div>
<span class="prev-blog-page"><a href="index.html">prev page [1]</a></span>
EOF

      last = site.pages.last
      expect(last.id).to eq("blog-page2")
      expect(last.__body).to eq(list2)
    end
  end # context "__build_entries"
end # context "Loki::Blog"
