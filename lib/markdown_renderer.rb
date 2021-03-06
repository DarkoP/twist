class MarkdownRenderer < Redcarpet::Render::HTML
  def paragraph(text)
    # Is special
    if text.gsub!(/^([TWAIDEQX])&gt;/, '')
      special(text, $1)
    # Begins with the footnote markings: [^footnote]:
    elsif footnote_prefix_regex.match(text.strip)
      footnote(text)
    else
      #inline footnotes
      footnote_regex = /\[\^([^\]]*)\]/ 
      if footnote_regex.match(text)
        text = text.gsub(footnote_regex) do
          @footnote_count += 1
          "<a href='#footnote_#{$1}'><sup>#{@footnote_count}</sup></a>"
        end
      end

      "<p>" + text + "</p>"
    end
  end

  def footnote(text)
    text = text.gsub(footnote_prefix_regex, '')
    "<div class='footnote'><a name='footnote_#{$1}' href='#'></a>#{text}</div>"
  end

  def block_code(code, language)
    if language == 'plain'
      "<div class='code'>" + Pygments.highlight(code) + "</div>"
    else
      "<div class='code'>" + Pygments.highlight(code, :lexer => language) + "</div>"
    end
  end

  def special(text, type)
    paragraphs = text.gsub("\n\n", "</p><p>")
    "<div class='#{convert_type(type)}'><p>" + paragraphs + "</p></div>"
  end

  def preprocess(full_document)
    @footnote_count = 0
    full_document = full_document.gsub(/^({[^}]*})$(.*?)^([^\s].*?\n)/m) do
      preprocess_code($1, $2.strip) + $3
    end

    # ARE YOU RETURNING A STRING HERE?!
    # If you don't, Redcarpet will raise a segfault
    full_document
  end

  def postprocess(full_document)
    html = Nokogiri::HTML(full_document)
    html.css("h2, h3").each_with_index do |header, index|
      header['class'] = 'section_title'
      header['id'] = "header_#{index}"
    end
    html.to_html
  end

  private

  def footnote_prefix_regex
    /^\[\^([^\]]*)\]:\s*/
  end

  def preprocess_code(details, code)
    output = ""
    details = Hash[details[1..-2].split(",").map do |detail|
      detail.split("=")
    end]
    if details['title']
      output = "**#{details['title'].gsub('_', '\\_')}**\n\n"
    end

    #outdent code
    code_lines = code.split("\n")
    outdented_code = code_lines[1..-1].map { |l| l.gsub(/^\s{4}/,'') }
    code = ([code_lines[0]] + [*outdented_code]).join("\n")

    output += "```#{details['lang']}\n#{code}\n```\n\n"
  end

  def convert_type(type)
    case type
      when 'T'
        'tip'
      when 'W'
        'warning'
      when 'A'
        'aside'
      when 'I'
        'information'
      when 'D'
        'discussion'
      when 'E'
        'error'
      when 'X'
        'exercise'
      when 'Q'
        'question'
    end
  end
end
