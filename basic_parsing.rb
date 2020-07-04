PARSE_RESULT = Struct.new(:results, :rest, :is_valid?, keyword_init: true)

def parse(parser, input)
  parser.call(input)
end

def choice(*parsers)
  lambda do |input|
    parsers.each do |parser|
      r = parse(parser, input)
      return r if r.is_valid?
    end

    PARSE_RESULT.new(results: [], rest: input, is_valid?: false)
  end
end

def sequence(*parsers)
  lambda do |input|
    results = []
    rest = input

    parsers.each do |parser|
      r = parse(parser, rest)
      return PARSE_RESULT.new(results: [], rest: input, is_valid?: false) unless r.is_valid?

      results << r.results
      rest = r.rest
    end

    PARSE_RESULT.new(results: results, rest: rest, is_valid?: true)
  end
end

def many(parser)
  lambda do |input|
    results = []
    rest = input

    loop do
      r = parse(parser, rest)
      break unless r.is_valid?

      results << r.results
      rest = r.rest
    end

    PARSE_RESULT.new(results: results, rest: rest, is_valid?: results.any?)
  end
end

def sep_by(separator_parser, value_parser)
  lambda do |input|
    results = []
    rest = input

    loop do
      value_r = parse(value_parser, rest)
      break unless value_r.is_valid?

      results << value_r.results
      rest = value_r.rest

      separator_r = parse(separator_parser, rest)
      break unless separator_r.is_valid?

      rest = separator_r.rest
    end

    PARSE_RESULT.new(results: results, rest: rest, is_valid?: results.any?)
  end
end

def end_of_input
  lambda do |input|
    if input.empty?
      PARSE_RESULT.new(results: [], rest: '', is_valid?: true)
    else
      PARSE_RESULT.new(results: [], rest: input, is_valid?: false)
    end
  end
end

def apply(f, parser)
  lambda do |input|
    r = parse(parser, input)
    return r unless r.is_valid?

    PARSE_RESULT.new(results: f.call(r.results), rest: r.rest, is_valid?: r.is_valid?)
  end
end

def chain(f, parser)
  lambda do |input|
    r = parse(parser, input)
    return r unless r.is_valid?

    new_parser = f.call(r.results)
    parse(new_parser, r.rest)
  end
end

def lazy(parser_thunk)
  lambda do |input|
    parse(parser_thunk.call, input)
  end
end

def between(left, content, right)
  apply(->(r) { r[1] }, sequence(left, content, right))
end

def lit_digit(i)
  lambda do |input|
    if input[0].to_i == i
      PARSE_RESULT.new(results: [i], rest: input[1..], is_valid?: true)
    else
      PARSE_RESULT.new(results: [], rest: input, is_valid?: false)
    end
  end
end

def any_char
  lambda do |input|
    if input[0]
      PARSE_RESULT.new(results: [input[0]], rest: input[1..], is_valid?: true)
    else
      PARSE_RESULT.new(results: [], rest: input, is_valid?: false)
    end
  end
end

def char_in(char_set)
  lambda do |input|
    if char_set.include?(input[0])
      PARSE_RESULT.new(results: [input[0]], rest: input[1..], is_valid?: true)
    else
      PARSE_RESULT.new(results: [], rest: input, is_valid?: false)
    end
  end
end

def str(word)
  lambda do |input|
    if input.start_with?(word)
      PARSE_RESULT.new(results: word, rest: input[word.size..], is_valid?: true)
    else
      PARSE_RESULT.new(results: [], rest: input, is_valid?: false)
    end
  end
end

def to_int(s)
  Integer(s)
end

def join_results(parser)
  apply(lambda { |x| x.join }, parser)
end

def flatten(parser)
  apply(lambda { |x| x.flatten }, parser)
end

def whitespace_char; char_in([' ', "\t", "\r", "\n", "\f", "\v"]) end
def whitespace; join_results(many(char_in([' ', "\t", "\r", "\n", "\f", "\v"]))) end
def digit; char_in([*'0'..'9']) end
def digits; join_results(many(digit)) end
def integer; apply(method(:to_int), digits) end
def letter; char_in([*'a'..'z', *'A'..'Z']) end
def letters; join_results(many(letter)) end

expression = nil

#add_term = map_apply(lambda { |(a, _, b)| a + b }, sequence(integer, lit_character('+'), integer))
add_term = apply(lambda { |(a, _, b)| a + b }, sequence(integer, str('+'), integer))
# add_term = sequence(integer, lit_character('+'), integer)
mult_term = apply(lambda { |(a, _, b)| a * b }, sequence(integer, str('*'), integer))
# mult_term = sequence(add_term, lit_character('*'), add_term)
#mult_term = choice(sequence(integer, lit_character('*'), integer), sequence(expression, lit_character('*'), expression))

expression = choice(add_term, mult_term)

# addition = apply(lambda { |(a, _, b)| Integer(a) + Integer(b) }, add_term)
# multiplication = apply(lambda { |(a, _, b)| Integer(a) * Integer(b) }, mult_term)
# expression = choice(addition, multiplication)

# parse_result = parse(choice(lit_character('h'), lit_character('e')), 'hello')
# parse_result = parse(sequence(lit_character('h'), lit_character('e')), 'hello')
# parse_result = parse(some(lit_character('h')), 'hhhhhee')
# parse_result = parse(map_apply(lambda { |s| s.upcase }, some(lit_character('h'))), 'hhhhhee')
# parse_result = parse(map_apply(lambda { |s| s.to_s }, some(digit)), '12345')
# parse_result = parse(map_apply(lambda { |s| s.to_s }, some(lit_character('h'))), '12345')
# parse_result = parse(some(digit), '12345')
# parse_result = parse(sequence(sequence(letters, some(whitespace)), some(char_in('world2'.split('')))), 'hello    world2')
# parse_result = parse(many(any_char), 'hello    world2')
# parse_result = parse(sequence(sequence(letters, digits), many(whitespace_char), letters, digit), 'hello34    world2')
# parse_result = parse(integer, '12345')

# parse_result = parse(sequence(integer, choice(choice(lit_character('+'), lit_character('*')), sequence(some(whitespace), choice(lit_character('+'), lit_character('*')), some(whitespace))), integer), '123 + 45')
# parse_result = parse(sequence(integer, some(whitespace), choice(lit_character('+'), lit_character('*')), some(whitespace), integer), '123 + 45')

parse_result = parse(apply(->(x) { x.upcase }, str('hello')), 'hello world')
parse_result = parse(letters, 'hello world')
parse_result = parse(between(str('('), letters, str(')')), '(hello )')

stringParser = apply(->(r) { { type: 'string', value: r} }, letters)
numberParser = apply(->(r) { { type: 'number', value: r} }, digits)
dicerollParser = apply(->((a, _, c)) { { type: 'diceroll', value: [to_int(a), to_int(c)] } }, sequence(digits, str('d'), digits))

parse_result = parse(
  chain(
    lambda do |type|
      case type
      when 'string'
        stringParser
      when 'number'
        numberParser
      when 'diceroll'
        dicerollParser
      end
    end,
    apply(->(r) { r[0] }, sequence(
      choice(str('string'), str('number'), str('diceroll')),
      str(':'))
    )
  ),
  'diceroll:2d8'
)

def value
  lazy(-> { choice(digits, array) })
end

def array
  between(str('['), sep_by(str(','), value), str(']'))
end

parse_result = parse(array, '[12,[4,4],65,7]')

# parse_result = parse(add_term, '2+3')
# parse_result = parse(expression, '2*3')
# parse_result = parse(mult_term, '10+2*2+3') # 15

#parse_result = parse(sequence(digits, end_of_input), '12') # 15

puts parse_result.results
p parse_result.results
p parse_result.rest
