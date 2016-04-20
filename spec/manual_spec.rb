require 'spec_helper'

# Add attrs for class inspection
class Loki::Manual
  attr_reader :name, :introduction, :sections
end

describe "Loki::Manual" do
  let(:manual_data) {
    ["manual", "intro",
      ["sec1", "1 text"],
      ["sec2", "2 text"],
      ["sec3", "3 text",
        ["subsec", "subsec text"],
        ["other", "other text"]
      ]
    ]
  }
  let(:page) { Loki::Page.new('a', 'b', ['page']) }
  let(:p_proc) { Loki::PageProcessor.new(page) }
  let(:manual) { Loki::Manual.new(manual_data, page) }

  let(:manual_html) do
    # This looks kind of dumb because my editor was being cranky
    html = <<EOF
<h1><span id="1"></span>manual</h1>
intro
<h2>Contents</h2>
<ul class="toc">
<li><a href="#1">1 Introduction</li>
<li><a href="#2"><span id="ret-2">2</span> sec1</a></li>
<li><a href="#3"><span id="ret-3">3</span> sec2</a></li>
<li><a href="#4"><span id="ret-4">4</span> sec3</a></li>
<ul>
<li><a href="#4.1"><span id="ret-4.1">4.1</span> subsec</a></li>
<li><a href="#4.2"><span id="ret-4.2">4.2</span> other</a></li>
</ul>
</ul>
<h2><a href="#ret-2"><span id="2">2</span> sec1</a></h2>
1 text
<h2><a href="#ret-3"><span id="3">3</span> sec2</a></h2>
2 text
<h2><a href="#ret-4"><span id="4">4</span> sec3</a></h2>
3 text
<h3><a href="#ret-4.1"><span id="4.1">4.1</span> subsec</a></h3>
subsec text
<h3><a href="#ret-4.2"><span id="4.2">4.2</span> other</a></h3>
other text
EOF
    html
  end

  context "init" do
    it "sets up name and intro" do
      expect(manual.name).to eq('manual')
      expect(manual.introduction).to eq('intro')
    end

    it "generates sections" do
      expect(manual.sections).to eq([
        ["sec1", "2", "1 text"],
        ["sec2", "3", "2 text"],
        ["sec3", "4", "3 text",
          ["subsec", "4.1", "subsec text"],
          ["other", "4.2", "other text"]
        ]])
    end
  end # context "init"

  context "name_to_section_index" do
    it "returns correct index" do
      expect(manual.name_to_section_index("sec2")).to eq("3")
    end

    it "returns correct subsection index" do
      expect(manual.name_to_section_index("sec3|other")).to eq("4.2")
    end

    it "returns introduction section" do
      expect(manual.name_to_section_index("Introduction")).to eq("1")
    end
  end # context "name_to_section_index"

  context "render" do
    it "renders simple manual" do
      expect(manual.render('path')).to eq(manual_html)
    end

    context "with reference" do

      let(:manual_data) {
        ["manual", "intro",
          ["sec1", "1 text"],
          ["sec2", "{ manual_ref('sec1') }"]
        ]
      }

      it "inserts reference link" do
        page.__init_manual_data(manual_data)

        html = <<EOF
<h1><span id="1"></span>manual</h1>
intro
<h2>Contents</h2>
<ul class="toc">
<li><a href="#1">1 Introduction</li>
<li><a href="#2"><span id="ret-2">2</span> sec1</a></li>
<li><a href="#3"><span id="ret-3">3</span> sec2</a></li>
</ul>
<h2><a href="#ret-2"><span id="2">2</span> sec1</a></h2>
1 text
<h2><a href="#ret-3"><span id="3">3</span> sec2</a></h2>
<a href="#2">sec1</a>
EOF
        expect(manual.render('path')).to eq(html)
      end
    end # context "with reference"

    context "render_manual directive" do
      it "integration test" do
        page.__init_manual_data(manual_data)

        page.id = "id"
        page.__body = "{render_manual}\n"

        html = <<EOF
<html>
<body>
#{manual_html}
</body>
</html>
EOF

        expect(FileUtils).to receive(:mkdir_p).with("b")
        expect(File).to receive(:write).with("b/page.html", html)

        expect {
          page.__build
        }.to output("page: a/views/page ->\n" +
                    "- writing: b/page.html\n\n").to_stdout
      end
    end # context "render directive"
  end
end
