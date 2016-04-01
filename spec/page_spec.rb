require 'spec_helper'

describe "Loki::Page" do
  let(:page) { Loki::Page.new("a", "b", ["path", "file"]) }

  context "load" do
    it "works" do
      allow(File).to receive(:read).with("a/views/path/file").
        and_return("id \"id\"\n--\n--\nstuff\n")

      expect {
        page.load
      }.to output("loading source: a/views/path/file\n").to_stdout

      expect(page.id).to eq("id")
      expect(page.body).to eq("--\nstuff\n")
    end
  end # context "load"

  context "build" do
    it "works" do
      page.id = "id"
      page.body = "one + one = {1 + 1}\n"

      html = <<EOF
<html>
<body>
one + one = 2
</body>
</html>
EOF

      site = Loki::Site.new

      expect(FileUtils).to receive(:mkdir_p).with("b/path")
      expect(File).to receive(:write).with("b/path/file.html", html)

      expect {
        page.build(site)
      }.to output("page: a/views/path/file ->\n" +
                  "- writing: b/path/file.html\n\n").to_stdout
    end
  end # context "build"

  context "page access" do
    it "works" do
      allow(File).to receive(:read).with("a/views/path/file").
        and_return("id \"id\"\n--\nstuff: {page.id}\n")

      html = <<EOF
<html>
<body>
stuff: id
</body>
</html>
EOF

      expect {
        page.load
      }.to output("loading source: a/views/path/file\n").to_stdout
      site = Loki::Site.new

      expect(FileUtils).to receive(:mkdir_p).with("b/path")
      expect(File).to receive(:write).with("b/path/file.html", html)

      expect {
        page.build(site)
      }.to output("page: a/views/path/file ->\n" +
                  "- writing: b/path/file.html\n\n").to_stdout
    end

    it "handles custom metadata with set" do
      allow(File).to receive(:read).with("a/views/path/file").
        and_return("id \"id\"\nset :key, \"value\"\nset \"foo\", \"bar\"" +
                   "\n--\nstuff: {page.key}\nalso: {page.foo}\n")

      html = <<EOF
<html>
<body>
stuff: value
also: bar
</body>
</html>
EOF

      expect {
        page.load
      }.to output("loading source: a/views/path/file\n").to_stdout
      site = Loki::Site.new

      expect(FileUtils).to receive(:mkdir_p).with("b/path")
      expect(File).to receive(:write).with("b/path/file.html", html)

      expect {
        page.build(site)
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

      site = Loki::Site.new
      site.__add_page(page)
      expect {
        site.__load_pages
      }.to output("loading source: a/views/path/file\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("b/path")
      expect(File).to receive(:write).with("b/path/file.html", html)

      expect {
        page.build(site)
      }.to output("page: a/views/path/file ->\n" +
                  "- writing: b/path/file.html\n\n").to_stdout
    end
  end # context "site access"

  context "source and dest" do
    it "returns source file and dest paths" do
      expect(page.source).to eq("a/views/path/file")
      expect(page.dest).to eq("b/path/file.html")
    end
  end # context "source and dest"

  context "validate_type" do
    it "validates string" do
      page.id = "id"

      # This won't raise error
      page.validate_type(:id, :string)
    end

    it "validates string_array" do
      page.tags = ["foo", "bar"]

      # This won't raise error
      page.validate_type(:tags, :string_array)
    end

    it "handles bad string" do
      msg = "Invalid type for id: expecting string, got 'true'\n\n"
      page.id = true

      expect {
        page.validate_type(:id, :string)
      }.to raise_error(StandardError, msg)
    end

    it "handles bad array" do
      msg = "Invalid type for tags: expecting string_array, got 'true'\n\n"
      page.tags = true

      expect {
        page.validate_type(:tags, :string_array)
      }.to raise_error(StandardError, msg)
    end

    it "handles bad string_array item" do
      msg = "Invalid type for tag: expecting string, got 'true'\n\n"
      page.tags = ["tag", true]

      expect {
        page.validate_type(:tags, :string_array)
      }.to raise_error(StandardError, msg)
    end

    it "handles bad type" do
      msg = "Internal error: undefined metadata type bar\n\n"
      page.id = "id"

      expect {
        page.validate_type(:id, :bar)
      }.to raise_error(StandardError, msg)
    end
  end
end # describe "Loki::Page"
