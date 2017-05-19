# encoding: utf-8

require "uri"

module AftonbladetHeadlines
  URL = "http://www.aftonbladet.se/"
  SELECTOR = ".abItemHLine h2, .abH"

  def self.headlines
    doc = Nokogiri::HTML(open(URL))

    doc.
      css(SELECTOR).
      map { |headline|
        text = headline.content.gsub(/ |\n/, ' ').strip

        link = headline.ancestors("a").first
        url = link ? URI.join("http://www.aftonbladet.se", link[:href]).to_s : nil

        [text, url]
      }.
      reject { |text, url| text.empty? }
  end
end
