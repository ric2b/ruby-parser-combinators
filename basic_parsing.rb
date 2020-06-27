PARSE_RESULT = Struct.new(:results, :rest, keyword_init: true)

def parse(parser, input)
  parser.call(input)
end

def choice(*parsers)
  lambda do |input|
    parsers.each do |parser|
      r = parse(parser, input)
      return r if r.results.any?
    end

    PARSE_RESULT.new(results: [], rest: input)
  end
end

def sequence(*parsers)
  lambda do |input|
    results = []
    rest = input

    parsers.each do |parser|
      r = parse(parser, rest)
      return PARSE_RESULT.new(results: [], rest: input) unless r.results.any?

      results.concat(r.results)
      rest = r.rest
    end

    PARSE_RESULT.new(results: results, rest: rest)
  end
end

def some(parser)
  lambda do |input|
    results = []
    rest = input

    loop do
      r = parse(parser, rest)
      break unless r.results.any?

      results.concat(r.results)
      rest = r.rest
    end

    PARSE_RESULT.new(results: results, rest: rest)
  end
end

def apply(f, parser)
  lambda do |input|
    r = parse(parser, input)
    PARSE_RESULT.new(results: r.results.map(&f), rest: r.rest)
  end
end

def lit_digit(i)
  lambda do |input|
    if input[0].to_i == i
      PARSE_RESULT.new(results: [i], rest: input[1..])
    else
      PARSE_RESULT.new(results: [], rest: input)
    end
  end
end

def any_char
  lambda do |input|
    if input[0]
      PARSE_RESULT.new(results: [input[0]], rest: input[1..])
    else
      PARSE_RESULT.new(results: [], rest: input)
    end
  end
end

def char_in(char_set)
  lambda do |input|
    if char_set.include?(input[0])
      PARSE_RESULT.new(results: [input[0]], rest: input[1..])
    else
      PARSE_RESULT.new(results: [], rest: input)
    end
  end
end

def lit_character(c)
  char_in([c])
end

whitespace = char_in([' ', "\t", "\r", "\n", "\f", "\v"])
digit = char_in([*'1'..'9'])
letter = char_in([*'a'..'z', *'A'..'Z'])
word = some(letter)

parse_result = parse(choice(lit_character('h'), lit_character('e')), 'hello')
# parse_result = parse(sequence(lit_character('h'), lit_character('e')), 'hello')
# parse_result = parse(some(lit_character('h'))), 'hhhhhee')
# parse_result = parse(apply(lambda { |s| s.upcase }, some(lit_character('h'))), 'hhhhhee')
# parse_result = parse(apply(lambda { |s| s.to_s }, some(lit_character('h'))), '12345')
# parse_result = parse(some(digit), '12345')
# parse_result = parse(sequence(sequence(word, some(whitespace)), some(char_in('world2'.split('')))), 'hello    world2')
# parse_result = parse(some(any_char), 'hello    world2')

puts parse_result.results.join
