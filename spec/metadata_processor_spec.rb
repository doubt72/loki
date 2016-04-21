require 'spec_helper'

describe "Loki::MetadataProcessor" do
  let(:page) { Loki::Page.new("/a", "/b", ["page"]) }
  let(:m_proc) { Loki::MetadataProcessor.new(page) }

  before(:each) do
    allow(page).to receive(:__site).and_return(Loki::Site.new)
  end

  context "__eval" do
    it "handles undefined param" do
      data = "foo\n"

      msg = "Error parsing metadata: invalid parameter 'foo'\n\n"

      expect {
        m_proc.__eval(data)
      }.to raise_error(StandardError, msg)
    end

    it "handles defined param" do
      data = "id 'foo'\n"

      m_proc.__eval(data)
      expect(page.id).to eq("foo")
    end

    it "handles multiple params" do
      data = "id 'foo'\ntitle 'bar'\n"

      m_proc.__eval(data)
      expect(page.id).to eq("foo")
      expect(page.title).to eq("bar")
    end

    it "handles block param" do
      data = "id do\n  'foo'\nend\n"

      m_proc.__eval(data)
      expect(page.id).to eq("foo")
    end

    it "handles syntax error" do
      data = "foo[\n"

      msg = /Error parsing metadata.*syntax error.*/m

      expect {
        m_proc.__eval(data)
      }.to raise_error(StandardError, msg)
    end

    it "page returns the page" do
      data = "id 'foo'\ntitle page.id"

      m_proc.__eval(data)
      expect(page.title).to eq("foo")
    end

    it "site returns the site" do
      data = "id site.class.to_s"

      m_proc.__eval(data)
      expect(page.id).to eq("Loki::Site")
    end

    it "manual_data loads data" do
      data = "manual_data ['manual', 'intro', ['section', 'section text']]"

      m_proc.__eval(data)
      expect(page.__manual_data.class).to eq(Loki::Manual)
      expect(page.__manual_data.name_to_section_index('Introduction')).
        to eq('1')
    end
  end # context "__eval"
end # describe "Loki::MetadataProcessor"
