require 'spec_helper'

describe "Loki" do
  context "self.generate" do
    it "returns error if source path doesn't exist" do
      msg = "Source path must exist.\n\n" +
        "Usage: loki <source> <destination>\n\n"

      allow(Dir).to receive(:exists?).with("source").and_return(false)

      expect {
        Loki.generate("source", "dest")
      }.to raise_error(StandardError, msg)
    end

    it "returns error if destination path doesn't exist" do
      msg = "Destination path must exist.\n\n" +
        "Usage: loki <source> <destination>\n\n"

      allow(Dir).to receive(:exists?).with("source").and_return(true)
      allow(Dir).to receive(:exists?).with("dest").and_return(false)

      expect {
        Loki.generate("source", "dest")
      }.to raise_error(StandardError, msg)
    end

    it "returns error if source path equals destination path" do
      msg = "Destination path must be different from source path.\n\n" +
        "Usage: loki <source> <destination>\n\n"

      allow(Dir).to receive(:exists?).with("source").and_return(true)

      expect {
        Loki.generate("source", "source")
      }.to raise_error(StandardError, msg)
    end

    it "returns error if views dir not found in source dir" do
      msg = "Source directory source/views must exist.\n\n"

      allow(Dir).to receive(:exists?).with("source").and_return(true)
      allow(Dir).to receive(:exists?).with("dest").and_return(true)
      allow(Dir).to receive(:exists?).with("source/views").and_return(false)

      expect {
        Loki.generate("source", "dest")
      }.to raise_error(StandardError, msg)
    end
  end # context "self.generate"

  context "config.rb check" do
    before(:each) do
      allow(Dir).to receive(:exists?).with("source").and_return(true)
      allow(Dir).to receive(:exists?).with("dest").and_return(true)
      allow(Dir).to receive(:exists?).with("source/views").and_return(true)
      allow(Dir).to receive(:exists?).with("source/assets").and_return(true)
      allow(Dir).to receive(:exists?).with("source/components").and_return(true)

      allow(Loki::Utils).to receive(:tree).with("source/views").
        and_return([["page"]])

      allow(File).to receive(:exists?).with("source/config.rb").and_return(true)
    end

    it "is handled correctly" do
      allow(File).to receive(:read).with("source/config.rb").
        and_return("set :id, 'id'\nset :foo, 'bar'")

      allow(File).to receive(:read).with("source/views/page").
        and_return("id site.id\n--\n{site.foo}")

      allow(File).to receive(:exists?).with("source/config_load.rb").
        and_return(false)

      allow(FileUtils).to receive(:mkdir_p).with("dest")

      html = <<EOF
<html>
<body>
bar</body>
</html>
EOF

      expect(File).to receive(:write).with("dest/page.html", html)

      output = <<EOF
manifest:
[["page"]]

loading source: source/views/page

page: source/views/page ->
- writing: dest/page.html

EOF

      expect {
        Loki.generate("source", "dest")
      }.to output(output).to_stdout
    end

    it "handles error" do
      allow(File).to receive(:read).with("source/config.rb").
        and_return("nope")

      output = <<EOF
manifest:
[["page"]]

EOF

      msg = /^Error reading source\/config.rb.*undefined.*nope/m

      expect {
        expect {
          Loki.generate("source", "dest")
        }.to raise_error(StandardError, msg)
      }.to output(output).to_stdout
    end
  end # context "config.rb check"

  context "config_load.rb check" do
    before(:each) do
      allow(Dir).to receive(:exists?).with("source").and_return(true)
      allow(Dir).to receive(:exists?).with("dest").and_return(true)
      allow(Dir).to receive(:exists?).with("source/views").and_return(true)
      allow(Dir).to receive(:exists?).with("source/assets").and_return(true)
      allow(Dir).to receive(:exists?).with("source/components").and_return(true)

      allow(Loki::Utils).to receive(:tree).with("source/views").
        and_return([["page"]])

      allow(File).to receive(:exists?).with("source/config.rb").and_return(false)
    end

    it "is handled correctly" do
      allow(File).to receive(:read).with("source/views/page").
        and_return("id 'id'\n--\n{site.foo}")

      allow(File).to receive(:exists?).with("source/config_load.rb").
        and_return(true)
      allow(File).to receive(:read).with("source/config_load.rb").
        and_return("set :foo, 'bar'")

      allow(FileUtils).to receive(:mkdir_p).with("dest")

      html = <<EOF
<html>
<body>
bar</body>
</html>
EOF

      expect(File).to receive(:write).with("dest/page.html", html)

      output = <<EOF
manifest:
[["page"]]

loading source: source/views/page

page: source/views/page ->
- writing: dest/page.html

EOF

      expect {
        Loki.generate("source", "dest")
      }.to output(output).to_stdout
    end

    it "handles error" do
      allow(File).to receive(:read).with("source/views/page").
        and_return("id 'id'\n--\n{site.foo}")

      allow(File).to receive(:exists?).with("source/config_load.rb").
        and_return(true)
      allow(File).to receive(:read).with("source/config_load.rb").
        and_return("nope")

      output = <<EOF
manifest:
[["page"]]

loading source: source/views/page
EOF

      msg = /^Error reading source\/config_load.rb.*undefined.*nope/m

      expect {
        expect {
          Loki.generate("source", "dest")
        }.to raise_error(StandardError, msg)
      }.to output(output).to_stdout
    end

    it "does not set values prematurely" do
      allow(File).to receive(:read).with("source/views/page").
        and_return("id site.nope\n--\n{site.foo}")

      output = <<EOF
manifest:
[["page"]]

loading source: source/views/page
EOF

      msg = /^Error parsing metadata.*undefined method.*nope/m

      expect {
        expect {
          Loki.generate("source", "dest")
        }.to raise_error(StandardError, msg)
      }.to output(output).to_stdout
    end
  end # context "config_load.rb check"
end # describe "Loki"
