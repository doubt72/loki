require 'spec_helper'

describe "Loki" do
  context "self.generate" do
    it "returns error if source path doesn't exist" do
      msg = "Source path must exist.\n\n" +
        "Usage: loki <source> <destination>\n\n"

      allow(Dir).to receive(:exists?).with("a").and_return(false)

      expect {
        Loki.generate("a", "b")
      }.to raise_error(StandardError, msg)
    end

    it "returns error if destination path doesn't exist" do
      msg = "Destination path must exist.\n\n" +
        "Usage: loki <source> <destination>\n\n"

      allow(Dir).to receive(:exists?).with("a").and_return(true)
      allow(Dir).to receive(:exists?).with("b").and_return(false)

      expect {
        Loki.generate("a", "b")
      }.to raise_error(StandardError, msg)
    end

    it "returns error if source path equals destination path" do
      msg = "Destination path must be different from source path.\n\n" +
        "Usage: loki <source> <destination>\n\n"

      allow(Dir).to receive(:exists?).with("a").and_return(true)

      expect {
        Loki.generate("a", "a")
      }.to raise_error(StandardError, msg)
    end

    it "returns error if views dir not found in source dir" do
      msg = "Source directory a/views must exist.\n\n"

      allow(Dir).to receive(:exists?).with("a").and_return(true)
      allow(Dir).to receive(:exists?).with("b").and_return(true)
      allow(Dir).to receive(:exists?).with("a/views").and_return(false)

      expect {
        Loki.generate("a", "b")
      }.to raise_error(StandardError, msg)
    end
  end # context "self.generate"

  context "config.rb check" do
    before(:each) do
      allow(Dir).to receive(:exists?).with("a").and_return(true)
      allow(Dir).to receive(:exists?).with("b").and_return(true)
      allow(Dir).to receive(:exists?).with("a/views").and_return(true)
      allow(Dir).to receive(:exists?).with("a/assets").and_return(true)
      allow(Dir).to receive(:exists?).with("a/components").and_return(true)

      allow(Loki::Utils).to receive(:tree).with("a/views").
        and_return([["page"]])

      allow(File).to receive(:exists?).with("a/config.rb").and_return(true)
    end

    it "is handled correctly" do
      allow(File).to receive(:read).with("a/config.rb").
        and_return("set :id, 'id'\nset :foo, 'bar'")

      allow(File).to receive(:read).with("a/views/page").
        and_return("id site.id\n--\n{site.foo}")

      allow(File).to receive(:exists?).with("a/config_load.rb").
        and_return(false)

      allow(FileUtils).to receive(:mkdir_p).with("b")

      html = <<EOF
<html>
<body>
bar</body>
</html>
EOF

      expect(File).to receive(:write).with("b/page.html", html)

      output = <<EOF
manifest:
[["page"]]

loading source: a/views/page

page: a/views/page ->
- writing: b/page.html

EOF

      expect {
        Loki.generate("a", "b")
      }.to output(output).to_stdout
    end

    it "handles error" do
      allow(File).to receive(:read).with("a/config.rb").
        and_return("nope")

      output = <<EOF
manifest:
[["page"]]

EOF

      msg = /^Error reading a\/config.rb.*undefined.*nope/m

      expect {
        expect {
          Loki.generate("a", "b")
        }.to raise_error(StandardError, msg)
      }.to output(output).to_stdout
    end
  end # context "config.rb check"

  context "config_load.rb check" do
    before(:each) do
      allow(Dir).to receive(:exists?).with("a").and_return(true)
      allow(Dir).to receive(:exists?).with("b").and_return(true)
      allow(Dir).to receive(:exists?).with("a/views").and_return(true)
      allow(Dir).to receive(:exists?).with("a/assets").and_return(true)
      allow(Dir).to receive(:exists?).with("a/components").and_return(true)

      allow(Loki::Utils).to receive(:tree).with("a/views").
        and_return([["page"]])

      allow(File).to receive(:exists?).with("a/config.rb").and_return(false)
    end

    it "is handled correctly" do
      allow(File).to receive(:read).with("a/views/page").
        and_return("id 'id'\n--\n{site.foo}")

      allow(File).to receive(:exists?).with("a/config_load.rb").
        and_return(true)
      allow(File).to receive(:read).with("a/config_load.rb").
        and_return("set :foo, 'bar'")

      allow(FileUtils).to receive(:mkdir_p).with("b")

      html = <<EOF
<html>
<body>
bar</body>
</html>
EOF

      expect(File).to receive(:write).with("b/page.html", html)

      output = <<EOF
manifest:
[["page"]]

loading source: a/views/page

page: a/views/page ->
- writing: b/page.html

EOF

      expect {
        Loki.generate("a", "b")
      }.to output(output).to_stdout
    end

    it "handles error" do
      allow(File).to receive(:read).with("a/views/page").
        and_return("id 'id'\n--\n{site.foo}")

      allow(File).to receive(:exists?).with("a/config_load.rb").
        and_return(true)
      allow(File).to receive(:read).with("a/config_load.rb").
        and_return("nope")

      output = <<EOF
manifest:
[["page"]]

loading source: a/views/page
EOF

      msg = /^Error reading a\/config_load.rb.*undefined.*nope/m

      expect {
        expect {
          Loki.generate("a", "b")
        }.to raise_error(StandardError, msg)
      }.to output(output).to_stdout
    end

    it "does not set values prematurely" do
      allow(File).to receive(:read).with("a/views/page").
        and_return("id site.nope\n--\n{site.foo}")

      output = <<EOF
manifest:
[["page"]]

loading source: a/views/page
EOF

      msg = /^Error parsing metadata.*undefined method.*nope/m

      expect {
        expect {
          Loki.generate("a", "b")
        }.to raise_error(StandardError, msg)
      }.to output(output).to_stdout
    end
  end # context "config_load.rb check"
end # describe "Loki"
