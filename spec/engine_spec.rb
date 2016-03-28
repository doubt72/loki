require 'spec_helper'

describe "Loki::Engine" do
  context "add" do
    it "loads page on add" do
      engine = Loki::Engine.new
      page = Loki::Page.new("a", "b", ["view"])

      expect(page).to receive(:load)

      engine.add(page)
    end
  end # context "add"
end # describe "Loki::Engine"
