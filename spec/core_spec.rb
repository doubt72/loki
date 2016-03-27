require 'spec_helper'

describe "Loki" do
  context "manifest validation" do
    it "handles empty list" do
      json = '[]' + "\n"

      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:read).and_return(json)

      expect(Loki.get_manifest('.')).to eq([])
    end

    it "handles nested lists correctly" do
      json = '["a", "b", ["c", ["d", "e"]]]' + "\n"

      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:read).and_return(json)

      expect(Loki.get_manifest(json)).to eq(JSON.parse(json))
    end

    it "handles bad input: top level" do
      json = '{"foo": "bar"}' + "\n"

      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:read).and_return(json)

      msg = "Error parsing manifest.json:\n'#{json.chomp}' must be array"

      expect do
        expect(Loki.get_manifest(json)).to ouput(msg).to_stdout
      end.to raise_error(SystemExit)
    end

    it "handles bad input: list item" do
      json = '["a", "b", ["c", [1, "e"]]]' + "\n"

      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:read).and_return(json)

      msg = "Error parsing manifest.json:\n'1' must be array or string"

      expect do
        expect(Loki.get_manifest(json)).to ouput(msg).to_stdout
      end.to raise_error(SystemExit)
    end
  end
end # describe "Loki"
