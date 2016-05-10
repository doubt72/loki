require 'spec_helper'

describe "Loki::BlogEntry" do
  let(:blog_entry) { Loki::BlogEntry.new("a", "b", ["path", "file"]) }
  let(:site) { Loki::Site.new }

  context "__load" do
    it "works" do
      allow(File).to receive(:read).with("a/views/path/file").
        and_return("id \"id\"\n--\n--\nstuff\n")

      expect {
        blog_entry.__load(site)
      }.to output("loading source: a/views/path/file\n").to_stdout

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
<body>
one + one = 2
</body>
</html>
EOF

      expect(FileUtils).to receive(:mkdir_p).with("b/path")
      expect(File).to receive(:write).with("b/path/file.html", html)

      expect {
        blog_entry.__build
      }.to output("page: a/views/path/file ->\n" +
                  "- writing: b/path/file.html\n\n").to_stdout
    end
  end # context "__build"

  context "page access" do
    it "works" do
      allow(File).to receive(:read).with("a/views/path/file").
        and_return("id \"id\"\n--\nstuff: {blog_entry.id}\n")

      html = <<EOF
<html>
<body>
stuff: id
</body>
</html>
EOF

      expect {
        blog_entry.__load(site)
      }.to output("loading source: a/views/path/file\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("b/path")
      expect(File).to receive(:write).with("b/path/file.html", html)

      expect {
        blog_entry.__build
      }.to output("page: a/views/path/file ->\n" +
                  "- writing: b/path/file.html\n\n").to_stdout
    end

    it "handles custom metadata with set" do
      allow(File).to receive(:read).with("a/views/path/file").
        and_return("id \"id\"\nset :key, \"value\"\nset \"foo\", \"bar\"" +
                   "\n--\nstuff: {blog_entry.key}\nalso: {blog_entry.foo}\n")

      html = <<EOF
<html>
<body>
stuff: value
also: bar
</body>
</html>
EOF

      expect {
        blog_entry.__load(site)
      }.to output("loading source: a/views/path/file\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("b/path")
      expect(File).to receive(:write).with("b/path/file.html", html)

      expect {
        blog_entry.__build
      }.to output("page: a/views/path/file ->\n" +
                  "- writing: b/path/file.html\n\n").to_stdout
    end

    it "handles custom metadata with global" do
      allow(File).to receive(:read).with("a/views/path/file").
        and_return("id \"id\"\nglobal :key, \"value\"\n" +
                   "global \"foo\", \"bar\"" +
                   "\n--\nstuff: {site.key}\nalso: {site.foo}\n")

      html = <<EOF
<html>
<body>
stuff: value
also: bar
</body>
</html>
EOF

      expect {
        blog_entry.__load(site)
      }.to output("loading source: a/views/path/file\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("b/path").twice
      expect(File).to receive(:write).with("b/path/file.html", html)

      page2 = Loki::BlogEntry.new("a", "b", ["path", "file2"])

      allow(File).to receive(:read).with("a/views/path/file2").
        and_return("id \"id2\"\n--\nstuff: {site.key}\nalso: {site.foo}\n")

      expect {
        page2.__load(site)
      }.to output("loading source: a/views/path/file2\n").to_stdout

      expect(File).to receive(:write).with("b/path/file2.html", html)

      # Swap the order as a minimal test of ordering
      expect {
        page2.__build
      }.to output("page: a/views/path/file2 ->\n" +
                  "- writing: b/path/file2.html\n\n").to_stdout

      expect {
        blog_entry.__build
      }.to output("page: a/views/path/file ->\n" +
                  "- writing: b/path/file.html\n\n").to_stdout
    end

    it "can set value inside page" do
      allow(File).to receive(:read).with("a/views/path/file").
        and_return("id \"id\"\n--\nstuff: " +
                   "{blog_entry.set :foo, \"bar\"\n\"stuff\"}\n" +
                   "also: {blog_entry.foo}\n")

      html = <<EOF
<html>
<body>
stuff: stuff
also: bar
</body>
</html>
EOF

      expect {
        blog_entry.__load(site)
      }.to output("loading source: a/views/path/file\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("b/path")
      expect(File).to receive(:write).with("b/path/file.html", html)

      expect {
        blog_entry.__build
      }.to output("page: a/views/path/file ->\n" +
                  "- writing: b/path/file.html\n\n").to_stdout
    end
  end # context "page access"

  context "site access" do
    it "works" do
      allow(File).to receive(:read).with("a/views/path/file").
        and_return("id \"id\"\n--\nstuff: " +
                   "{ site.__lookup_path('a', 'b', 'id') }\n")

      html = <<EOF
<html>
<body>
stuff: path/file.html
</body>
</html>
EOF

      site.__add_page(blog_entry)
      expect {
        site.__load_pages
      }.to output("loading source: a/views/path/file\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("b/path")
      expect(File).to receive(:write).with("b/path/file.html", html)

      expect {
        blog_entry.__build
      }.to output("page: a/views/path/file ->\n" +
                  "- writing: b/path/file.html\n\n").to_stdout
    end
  end # context "site access"

  context "source and dest" do
    it "returns source file and dest paths" do
      expect(blog_entry.__source_path).to eq("a/views/path/file")
      expect(blog_entry.__destination_path).to eq("b/path/file.html")
    end
  end # context "source and dest"

  context "date" do
    it "works" do
      expect(true).to be(false)
    end
  end # context "date"

  context "date_sidebar" do
    it "works" do
      expect(true).to be(false)
    end
  end # context "date"

  context "tag_sidebar" do
    it "works" do
      expect(true).to be(false)
    end
  end # context "date"

  context "rss_feed" do
    it "works" do
      expect(true).to be(false)
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
