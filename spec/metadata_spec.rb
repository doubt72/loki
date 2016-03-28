require 'spec_helper'

describe "Loki::Metadata" do
  context "eval" do
    it "handles undefined param" do
      data = "foo\n"
      page = Loki::Page.new("/a", "/b", ["view"])

      msg = "Error parsing metadata: invalid parameter 'foo'\n\n"

      expect {
        Loki::Metadata.eval(data, page)
      }.to raise_error(StandardError, msg)
    end

    it "handles defined param" do
      data = "id 'foo'\n"
      page = Loki::Page.new("/a", "/b", ["view"])

      Loki::Metadata.eval(data, page)
      expect(page.id).to eq("foo")
    end

    it "handles multiple params" do
      data = "id 'foo'\ntitle 'bar'\n"
      page = Loki::Page.new("/a", "/b", ["view"])

      Loki::Metadata.eval(data, page)
      expect(page.id).to eq("foo")
      expect(page.title).to eq("bar")
    end

    it "handles block param" do
      data = "id do\n  'foo'\nend\n"
      page = Loki::Page.new("/a", "/b", ["view"])

      Loki::Metadata.eval(data, page)
      expect(page.id).to eq("foo")
    end

    it "handles syntax error" do
      data = "foo[\n"
      page = Loki::Page.new("/a", "/b", ["view"])

      msg = /Error parsing metadata.*syntax error.*/m

      expect {
        Loki::Metadata.eval(data, page)
      }.to raise_error(StandardError, msg)
    end
  end # context "eval"
end # describe "Loki::Metadata"
