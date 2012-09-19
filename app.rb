# Tiny Sinatra quiz app: determine which (Swedish) Aftonbladet headlines are real and which are generated from Markov chains.
# By Henrik Nyh <henrik@nyh.se> 2010-07-29 under the MIT license.

require "open-uri"

Dir["./lib/*.rb"].each { |f| require f }

require "rubygems"
require "bundler"
Bundler.require :default, (ENV['RACK_ENV'] || "development").to_sym

set :haml, :format => :html5, :attr_wrapper => %{"}
set :views, lambda { root }

set :default_count, 10
set :title, "Man or Markov?"

get '/' do
  @title = settings.title

  headlines = AftonbladetHeadlines.headlines

  mc = MarkovChain.new(headlines.map { |text, url| text })

  # We should only list headlines of at least three words, since shorter headlines must always exist in the page.
  listable_headlines = headlines.select { |text, url| text.count(" ") >= 2 }

  count = params[:count].to_i.nonzero? || settings.default_count

  @data = []
  count.times do
    if rand(2).zero?
      headline, url = listable_headlines[rand(listable_headlines.length)]
      @data << [headline, url, true]
    else
      max_words = 20 + rand(10)
      headline = mc.get_unique_line(max_words)
      headline = HeadlineNormalizer.normalize(headline)
      @data << [headline, nil, false]
    end
  end

  haml :index
end
