require 'spec_helper'

describe "Loki::Page" do
  let(:page) { Loki::Page.new("a", "b", ["path", "file"]) }
  let(:site) { Loki::Site.new }

  context "__load" do
    it "works" do
      allow(File).to receive(:read).with("a/views/path/file").
        and_return("id \"id\"\n--\n--\nstuff\n")

      expect {
        page.__load(site)
      }.to output("loading source: a/views/path/file\n").to_stdout

      expect(page.id).to eq("id")
      expect(page.__body).to eq("--\nstuff\n")
    end
  end # context "__load"

  context "__build" do
    it "works" do
      page.id = "id"
      page.__body = "one + one = {1 + 1}\n"

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
        page.__build
      }.to output("page: a/views/path/file ->\n" +
                  "- writing: b/path/file.html\n\n").to_stdout
    end
  end # context "__build"

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
        page.__load(site)
      }.to output("loading source: a/views/path/file\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("b/path")
      expect(File).to receive(:write).with("b/path/file.html", html)

      expect {
        page.__build
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
        page.__load(site)
      }.to output("loading source: a/views/path/file\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("b/path")
      expect(File).to receive(:write).with("b/path/file.html", html)

      expect {
        page.__build
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
        page.__load(site)
      }.to output("loading source: a/views/path/file\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("b/path").twice
      expect(File).to receive(:write).with("b/path/file.html", html)

      page2 = Loki::Page.new("a", "b", ["path", "file2"])

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
        page.__build
      }.to output("page: a/views/path/file ->\n" +
                  "- writing: b/path/file.html\n\n").to_stdout
    end

    it "can set value inside page" do
      allow(File).to receive(:read).with("a/views/path/file").
        and_return("id \"id\"\n--\nstuff: " +
                   "{page.set :foo, \"bar\"\n\"stuff\"}\n" +
                   "also: {page.foo}\n")

      html = <<EOF
<html>
<body>
stuff: stuff
also: bar
</body>
</html>
EOF

      expect {
        page.__load(site)
      }.to output("loading source: a/views/path/file\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("b/path")
      expect(File).to receive(:write).with("b/path/file.html", html)

      expect {
        page.__build
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

      site.__add_page(page)
      expect {
        site.__load_pages
      }.to output("loading source: a/views/path/file\n").to_stdout

      expect(FileUtils).to receive(:mkdir_p).with("b/path")
      expect(File).to receive(:write).with("b/path/file.html", html)

      expect {
        page.__build
      }.to output("page: a/views/path/file ->\n" +
                  "- writing: b/path/file.html\n\n").to_stdout
    end
  end # context "site access"

  context "source and dest" do
    it "returns source file and dest paths" do
      expect(page.__source_path).to eq("a/views/path/file")
      expect(page.__destination_path).to eq("b/path/file.html")
    end
  end # context "source and dest"

  context "__validate_type" do
    it "handles bad type" do
      msg = "Internal error: undefined metadata type bar\n\n"
      page.id = "id"

      expect {
        page.__validate_type(:id, :bar)
      }.to raise_error(StandardError, msg)
    end
  end # context "__validate_type"
end # describe "Loki::Page"
