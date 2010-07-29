# Tiny Sinatra quiz app: determine which (Swedish) Aftonbladet headlines are real and which are generated from Markov chains.
# By Henrik Nyh <henrik@nyh.se> 2010-07-29 under the MIT license.

require "rubygems"
require "sinatra"
require "haml"
require "sass"

DEFAULT_COUNT = 10
TITLE = "Man or Markov?"
TEMPLATE = DATA.read

set :haml, :format => :html5, :attr_wrapper => %{"}

get '/' do
  
  @title = TITLE
  
  headlines = Aftonbladet.new.headlines
  mc = MarkovChain.new(headlines.map { |text, url| text })
  
  count = params[:count].to_i.nonzero? || DEFAULT_COUNT

  @data = []
  count.times do
    if rand(2).zero?
      headline, url = headlines[rand(headlines.length)]
      @data << [headline, url, true]
    else
      max_words = 20 + rand(10)
      headline = mc.get_unique_line(max_words)
      @data << [headline, nil, false]
    end
  end

  haml TEMPLATE
end


# Based on http://rubyquiz.com/quiz74.html
class MarkovChain

  def initialize(text)
    @words = Hash.new { |h,k| h[k] = Hash.new(0) }
    @starters = []
    add_by_line(text)
  end

  def get_line(max_words=nil)
    words = []
    word = starter
    until !word || (max_words && words.length == max_words)
      words << word
      word = get(word)
    end
    words.join(" ")
  end
  
  def get_unique_line(max_words=nil)
    tries = 100
    while tries > 0 do
      line = get_line(max_words)
      if @lines.include?(line)
        tries -= 1
        next
      else
        return line
      end
    end
    nil
  end
  
private

  def add_by_line(text)
    @lines = text.is_a?(Array) ? text : text.to_s.split(/[\r\n]+/)
    @lines.each do |line|
      words = line.split
      next if words.empty?
      @starters << words.first
      words.each_with_index do |word, index|
        if next_word = words[index+1]
          add(word, next_word)
        end
      end
    end
  end

  def add(word, next_word)
    @words[word][next_word] += 1
  end

  def get(word)
    followers = @words[word]
    return nil unless followers
    sum = followers.inject(0) { |sum, (key, value)| sum += value }
    random = rand(sum)+1
    partial_sum = 0
    next_word, next_count = followers.find do |word, count|
      partial_sum += count
      partial_sum >= random
    end
    next_word
  end
  
  def starter
    @starters[rand(@starters.length)]
  end
 
end


require "open-uri"
require "rubygems"
require "hpricot"
class Aftonbladet
  def initialize
    @doc = Hpricot(open("http://www.aftonbladet.se/"))
  end
  
  def headlines
    selector = 'h2 a, #abPilramContainer .abLink a:not([@href^="http://blog."])'  # Blog links are not headlines.
    @doc.search(selector).map { |a| [a.inner_text.gsub(/ |\n/, ' ').strip, a[:href]] }.reject { |text, url| text.empty? || text.count(" ").zero? }
  end
end


__END__
!!!
%html
  %head
    %meta(http-equiv="Content-Type" content="text/html; charset=utf-8")
    %title= @title
    %style
      :sass
        body
          .headline
            font-weight: bold
          .answer
            margin-top: -1em
            display: none
        body.revealed
          .answer
            display: block
          .real .answer
            color: #0C0
          .fake .answer
            color: #C00
    :javascript
      function facit() {
        document.body.className = document.body.className=="revealed" ? "" : "revealed";
        return false;
      }

    %body
      %h1= @title
      %p Vissa av följande rubriker från Aftonbladet är riktiga, vissa är <a href="http://sv.wikipedia.org/wiki/Markovkedja">stokastiskt genererade</a>. Gissa!
      %ol
        - @data.each do |headline, url, real|
          %li{ :class => (real ? 'real' : 'fake') }
            %p.headline= Rack::Utils.escape_html headline
            %p.answer
              - if real
                == ✓ Riktig rubrik - <a href="#{url}">läs artikeln</a>
              - else
                ✗ Markov
            
      %p <a href="javascript:facit()">Dölj/visa facit</a>
      %p <a href="/">Visa fler</a>
