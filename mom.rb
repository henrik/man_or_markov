# encoding: utf-8

# Tiny Sinatra quiz app: determine which (Swedish) Aftonbladet headlines are real and which are generated from Markov chains.
# By Henrik Nyh <henrik@nyh.se> 2010-07-29 under the MIT license.

require "open-uri"
require "./lib/markov_chain"

require "rubygems"
require "bundler"
Bundler.require :default, (ENV['RACK_ENV'] || "development").to_sym

DEFAULT_COUNT = 10
TITLE = "Man or Markov?"

set :haml, :format => :html5, :attr_wrapper => %{"}
set :views, lambda { root }

get '/' do
  @title = TITLE

  headlines = Aftonbladet.new.headlines

  mc = MarkovChain.new(headlines.map { |text, url| text })

  # We should only list headlines of at least three words, since shorter headlines must always exist in the page.
  listable_headlines = headlines.select { |text, url| text.count(" ") >= 2 }

  count = params[:count].to_i.nonzero? || DEFAULT_COUNT

  @data = []
  count.times do
    if rand(2).zero?
      headline, url = listable_headlines[rand(listable_headlines.length)]
      @data << [headline, url, true]
    else
      max_words = 20 + rand(10)
      headline = mc.get_unique_line(max_words)
      headline = balance_quotes(headline)
      @data << [headline, nil, false]
    end
  end

  haml :index
end


# Unbalanced quotes is a dead giveaway, so balance them.

def balance_quotes(text)
  odd_number_of_quotes = text.scan(/[”"]/).length % 2 == 1
  return text unless odd_number_of_quotes  # We might have e.g.: ”Foo” is a bar.
  case text
  when /\A([^”"].*)[”"]\z/u  # Quote at end but not start.
    $1  # Remove the quote.
  when /\A.*([”"])[^”"]+\z/u    # Last quote somewhere before the end.
    text + $1  # Add a quote at the end.
  else
    text
  end
end


class Aftonbladet
  def initialize
    @doc = Nokogiri::HTML(open("http://www.aftonbladet.se/"))
  end

  def headlines
    selector = '.abItemHLine h2, .abH'
    @doc.css(selector).map { |headline|
      text = headline.content.gsub(/ |\n/, ' ').strip

      link = headline.ancestors("a").first
      url = link ? link[:href] : nil

      [text, url]
    }.
    reject { |text, url| text.empty? }
  end
end
