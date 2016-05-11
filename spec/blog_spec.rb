require 'spec_helper'

# For inspection
class Loki::Blog
  def entries
    @entries
  end
end

describe "Loki::Blog" do
  let(:site) { Loki::Site.new }
  let(:blog) { Loki::Blog.new(site) }
  let(:body) { "id 'entry'\ntitle 'title'\ndate '2016-01-01'\n--\nentry\n" }

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
      foo_body = "id 'entry'\n--\nfoo\n"
      bar_body = "id 'entry'\n--\nbar\n"

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
      html = "<html>\n<head>\n  <title>title</title>\n</head>\n" +
        "<body>\nentry\n</body>\n</html>\n"

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
      #expect(true).to be(false)
    end

    it "generates rss if generate_rss set" do
      blog.directory = "blog"
      blog.generate_rss = true
      blog.main_title = "main title"
      blog.description = "description"
      blog.site_link = "http://www.example.com"
      html = "<html>\n<head>\n  <title>title</title>\n</head>\n" +
        "<body>\nentry\n</body>\n</html>\n"

      allow(Dir).to receive(:entries).with("source/blog").
        and_return([".", "..", "entry"])
      allow(File).to receive(:directory?).with("source/blog/.").and_return(true)
      allow(File).to receive(:directory?).with("source/blog/..").
        and_return(true)
      allow(File).to receive(:directory?).with("source/blog/entry").
        and_return(false)

#      expect(File).to receive(:read).with("source/blog/entry").
#        and_return(body)

#      expect(FileUtils).to receive(:mkdir_p).with("dest/blog")
#      expect(File).to receive(:write).with("dest/blog/rss.xml", html)

#      expect {
#        blog.__load_entries("source", "dest")
#      }.to output("loading source: source/blog/entry\n").to_stdout

#      expect(File).to receive(:write).with("dest/blog/entry.html", html)

#      expect {
#        blog.__build_entries
#      }.to output("page: source/blog/entry ->\n" +
#                  "- writing: dest/blog/entry.html\n\n").to_stdout
      #expect(true).to be(false)
    end
  end # context "__build_entries"
end # context "Loki::Blog"
