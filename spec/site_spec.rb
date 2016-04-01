require 'spec_helper'

describe "Loki::Site" do
  context "add" do
    it "handles duplicate ids" do
      site = Loki::Site.new
      page = Loki::Page.new("a", "b", ["view"])
      page.id = "foo"

      allow(page).to receive(:__load)
      site.__add_page(page)

      page2 = Loki::Page.new("a", "b", ["view2"])
      page2.id = "foo"

      msg = "Error loading page: duplicate id 'foo'\n\n"

      site.__add_page(page)
      site.__add_page(page2)

      allow(page2).to receive(:__load)

      expect {
        site.__load_pages
      }.to raise_exception(StandardError, msg)
    end
  end # context "add"

  context "lookup" do
    it "can find id" do
      site = Loki::Site.new
      page = Loki::Page.new("a", "b", ["view", "page"])
      page.id = "id"

      site.__add_page(page)

      expect(site.__lookup_path("a", "b", "id")).to eq("view/page.html")
    end

    it "can find asset" do
      site = Loki::Site.new

      allow(File).to receive(:exists?).with("a/assets/id.png").and_return(true)
      allow(Loki::Utils).to receive(:copy_asset)

      expect(site.__lookup_path("a", "b", "id.png")).to eq("assets/id.png")
    end

    it "raises exception when no match found" do
      site = Loki::Site.new

      msg = "Error on line 0 of file a/views/path/file:\n" +
        "couldn't link to 'unknown', no match found.\n\n"

      expect {
        site.__lookup_path("a", "b", "unknown")
      }.to raise_exception(StandardError, msg)
    end
  end # context "lookup"
end # describe "Loki::Site"
