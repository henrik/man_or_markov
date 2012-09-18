# encoding: utf-8

module HeadlineNormalizer
  def self.normalize(text)
    text = balance_quotes(text)
    unbreak_hyphenation(text)
  end

  # Unbalanced quotes is a dead giveaway, so balance them.
  def self.balance_quotes(text)
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

  def self.unbreak_hyphenation(text)
    text.gsub(/(\w)- /, '\1')
  end
end
