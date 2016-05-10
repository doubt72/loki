require 'spec_helper'

describe "Loki::Utils" do
  context "tree" do
    it "returns contents of directory" do
      allow(Dir).to receive(:entries).and_return([".", "..", "a", "b"])
      allow(Dir).to receive(:exists?).and_return(false)

      expect(Loki::Utils.tree('.')).to eq([["a"], ["b"]])
    end

    it "handles subdirectories" do
      allow(Dir).to receive(:entries).with(".").
        and_return([".", "..", "a", "b", "c"])
      allow(Dir).to receive(:entries).with("./c").
        and_return([".", "..", "d", "e", "f"])
      allow(Dir).to receive(:entries).with("./c/e").
        and_return([".", "..", "g", "h", "i"])

      allow(Dir).to receive(:exists?).with("./a").and_return(false)
      allow(Dir).to receive(:exists?).with("./b").and_return(false)
      allow(Dir).to receive(:exists?).with("./c").and_return(true)
      allow(Dir).to receive(:exists?).with("./c/d").and_return(false)
      allow(Dir).to receive(:exists?).with("./c/e").and_return(true)
      allow(Dir).to receive(:exists?).with("./c/f").and_return(false)
      allow(Dir).to receive(:exists?).with("./c/e/g").and_return(false)
      allow(Dir).to receive(:exists?).with("./c/e/h").and_return(false)
      allow(Dir).to receive(:exists?).with("./c/e/i").and_return(false)

      expect(Loki::Utils.tree('.')).
        to eq([
               ["a"],
               ["b"],
               ["c", "d"],
               ["c", "e", "g"],
               ["c", "e", "h"],
               ["c", "e", "i"],
               ["c", "f"]
              ])
    end
  end # context "tree"

  context "validate_type" do
    it "validates string" do
      # This won't raise error
      Loki::Utils.validate_type(:id, "id", :string)
    end

    it "validates string_array" do
      # This won't raise error
      Loki::Utils.validate_type(:tags, ["foo", "bar"], :string_array)
    end

    it "validates favicon_array" do
      data = [[16, "icon", "favicon.png"],
        [32, "icon", "favicon.png"]]

      # This won't raise error
      Loki::Utils.validate_type(:favicon, data, :favicon_array)
    end

    it "handles bad string" do
      msg = "Invalid type for id: expecting string, got 'true'\n\n"

      expect {
        Loki::Utils.validate_type(:id, true, :string)
      }.to raise_error(StandardError, msg)
    end

    it "handles bad array" do
      msg = "Invalid type for tags: expecting string_array, got 'true'\n\n"

      expect {
        Loki::Utils.validate_type(:tags, true, :string_array)
      }.to raise_error(StandardError, msg)
    end

    it "handles bad string_array item" do
      msg = "Invalid type for tag: expecting string, got 'true'\n\n"
      data = ["tag", true]

      expect {
        Loki::Utils.validate_type(:tags, data, :string_array)
      }.to raise_error(StandardError, msg)
    end

    it "handles bad favicon_array" do
      msg = "Invalid type for favicon: expecting favicon_array, got 'true'\n\n"

      expect {
        Loki::Utils.validate_type(:favicon, true, :favicon_array)
      }.to raise_error(StandardError, msg)
    end

    it "handles bad favicon_array item" do
      msg = "Invalid type for favicon spec: expecting array, got 'true'\n\n"

      expect {
        Loki::Utils.validate_type(:favicon, [true], :favicon_array)
      }.to raise_error(StandardError, msg)
    end

    it "handles bad favicon size" do
      msg = "Invalid type for favicon size: expecting integer, got 'true'\n\n"
      data = [[true, "icon", "favicon.png"]]

      expect {
        Loki::Utils.validate_type(:favicon, data, :favicon_array)
      }.to raise_error(StandardError, msg)
    end

    it "handles bad favicon type" do
      msg = "Invalid type for favicon type: expecting string, got 'true'\n\n"
      data = [[32, true, "favicon.png"]]

      expect {
        Loki::Utils.validate_type(:favicon, data, :favicon_array)
      }.to raise_error(StandardError, msg)
    end

    it "handles bad favicon path" do
      msg = "Invalid type for favicon path: expecting string, got 'true'\n\n"
      data = [[32, "icon", true]]

      expect {
        Loki::Utils.validate_type(:favicon, data, :favicon_array)
      }.to raise_error(StandardError, msg)
    end

    it "handles bad type" do
      msg = "Internal error: undefined metadata type bar\n\n"

      expect {
        Loki::Utils.validate_type(:id, "id", :bar)
      }.to raise_error(StandardError, msg)
    end
  end # context "validate_type"
end # describe "Loki::Utils"
