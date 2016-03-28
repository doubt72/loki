require 'spec_helper'

describe "Loki" do
  context "generate" do
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
  end # context "generate"
end # describe "Loki"
