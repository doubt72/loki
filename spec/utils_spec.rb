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
end # describe "Loki::Utils"
