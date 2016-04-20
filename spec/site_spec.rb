require 'spec_helper'

describe "Loki::Site" do
  let(:site) { Loki::Site.new }

  context "add" do
    it "handles duplicate ids" do
      page = Loki::Page.new("a", "b", ["view"])
      page.id = "foo"

      page2 = Loki::Page.new("a", "b", ["view2"])
      page2.id = "foo"

      msg = "Error loading page: duplicate id 'foo'\n\n"

      site.__add_page(page)
      site.__add_page(page2)

      allow(page).to receive(:__load)
      allow(page2).to receive(:__load)

      expect {
        site.__load_pages
      }.to raise_error(StandardError, msg)
    end
  end # context "add"

  context "lookup" do
    it "can find id" do
      page = Loki::Page.new("a", "b", ["view", "page"])
      page.id = "id"

      site.__add_page(page)

      expect(site.__lookup_path("a", "b", "id")).to eq("view/page.html")
    end

    it "can find asset" do
      allow(File).to receive(:exists?).with("a/assets/id.png").and_return(true)
      allow(Loki::Utils).to receive(:copy_asset)

      expect(site.__lookup_path("a", "b", "id.png")).to eq("assets/id.png")
    end

    it "raises exception when no match found" do
      msg = "couldn't link to 'unknown', no match found."

      expect {
        site.__lookup_path("a", "b", "unknown")
      }.to raise_error(StandardError, msg)
    end
  end # context "lookup"
end # describe "Loki::Site"
