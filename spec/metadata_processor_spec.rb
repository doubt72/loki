require 'spec_helper'

describe "Loki::MetadataProcessor" do
  context "eval" do
    it "handles undefined param" do
      data = "foo\n"
      page = Loki::Page.new("/a", "/b", ["view"])

      msg = "Error parsing metadata: invalid parameter 'foo'\n\n"

      expect {
        Loki::MetadataProcessor.eval(data, page, Loki::Site.new)
      }.to raise_error(StandardError, msg)
    end

    it "handles defined param" do
      data = "id 'foo'\n"
      page = Loki::Page.new("/a", "/b", ["view"])

      Loki::MetadataProcessor.eval(data, page, Loki::Site.new)
      expect(page.id).to eq("foo")
    end

    it "handles multiple params" do
      data = "id 'foo'\ntitle 'bar'\n"
      page = Loki::Page.new("/a", "/b", ["view"])

      Loki::MetadataProcessor.eval(data, page, Loki::Site.new)
      expect(page.id).to eq("foo")
      expect(page.title).to eq("bar")
    end

    it "handles block param" do
      data = "id do\n  'foo'\nend\n"
      page = Loki::Page.new("/a", "/b", ["view"])

      Loki::MetadataProcessor.eval(data, page, Loki::Site.new)
      expect(page.id).to eq("foo")
    end

    it "handles syntax error" do
      data = "foo[\n"
      page = Loki::Page.new("/a", "/b", ["view"])

      msg = /Error parsing metadata.*syntax error.*/m

      expect {
        Loki::MetadataProcessor.eval(data, page, Loki::Site.new)
      }.to raise_error(StandardError, msg)
    end

    it "page returns the page" do
      data = "id 'foo'\ntitle page.id"
      page = Loki::Page.new("/a", "/b", ["view"])

      Loki::MetadataProcessor.eval(data, page, Loki::Site.new)
      expect(page.title).to eq("foo")
    end

    it "site returns the site" do
      data = "id site.class.to_s"
      page = Loki::Page.new("/a", "/b", ["view"])

      Loki::MetadataProcessor.eval(data, page, Loki::Site.new)
      expect(page.id).to eq("Loki::Site")
    end
  end # context "eval"
end # describe "Loki::MetadataProcessor"
