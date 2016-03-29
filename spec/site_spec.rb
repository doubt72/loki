require 'spec_helper'

describe "Loki::Site" do
  context "add" do
    it "loads page on add" do
      site = Loki::Site.new
      page = Loki::Page.new("a", "b", ["view"])

      expect(page).to receive(:load)

      site.add(page)
    end

    it "handles duplicate ids" do
      site = Loki::Site.new
      page = Loki::Page.new("a", "b", ["view"])
      page.id = "foo"

      allow(page).to receive(:load)
      site.add(page)

      page2 = Loki::Page.new("a", "b", ["view2"])
      page2.id = "foo"

      msg = "Error loading page: duplicate id 'foo'\n\n"

      allow(page2).to receive(:load)

      expect {
        site.add(page)
      }.to raise_exception(StandardError, msg)
    end
  end # context "add"

  context "lookup" do
    it "can find id" do
      site = Loki::Site.new
      page = Loki::Page.new("a", "b", ["view", "page"])
      page.id = "id"

      allow(page).to receive(:load)

      site.add(page)

      expect(site.lookup_path("a", "b", "id")).to eq("view/page.html")
    end

    it "can find asset" do
      site = Loki::Site.new

      allow(File).to receive(:exists?).with("a/assets/id.png").and_return(true)
      allow(Loki::Utils).to receive(:copy_asset)

      expect(site.lookup_path("a", "b", "id.png")).to eq("assets/id.png")
    end

    it "raises exception when no match found" do
      site = Loki::Site.new

      msg = "Error processing page: " +
        "couldn't link to 'unknown', no match found.\n\n"

      expect {
        site.lookup_path("a", "b", "unknown")
      }.to raise_exception(StandardError, msg)
    end
  end # context "lookup"
end # describe "Loki::Site"
