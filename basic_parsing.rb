module Parsing
  STATE = Struct.new(:result, :rest, :is_valid?, keyword_init: true)

  module_function

  def parse(parser, input)
    parser.call(input)
  end

  def choice(*parsers)
    lambda do |input|
      parsers.each do |parser|
        r = parse(parser, input)
        return r if r.is_valid?
      end

      STATE.new(result: [], rest: input, is_valid?: false)
    end
  end

  def sequence(*parsers)
    lambda do |input|
      results = []
      rest = input

      parsers.each do |parser|
        r = parse(parser, rest)
        return STATE.new(result: [], rest: input, is_valid?: false) unless r.is_valid?

        results << r.result
        rest = r.rest
      end

      STATE.new(result: results, rest: rest, is_valid?: true)
    end
  end

  def many(parser)
    lambda do |input|
      results = []
      rest = input

      loop do
        r = parse(parser, rest)
        break unless r.is_valid?

        results << r.result
        rest = r.rest
      end

      STATE.new(result: results, rest: rest, is_valid?: results.any?)
    end
  end

  def sep_by(separator_parser, value_parser)
    lambda do |input|
      results = []
      rest = input

      loop do
        value_r = parse(value_parser, rest)
        break unless value_r.is_valid?

        results << value_r.result
        rest = value_r.rest

        separator_r = parse(separator_parser, rest)
        break unless separator_r.is_valid?

        rest = separator_r.rest
      end

      STATE.new(result: results, rest: rest, is_valid?: results.any?)
    end
  end

  def end_of_input
    lambda do |input|
      if input.empty?
        STATE.new(result: [], rest: '', is_valid?: true)
      else
        STATE.new(result: [], rest: input, is_valid?: false)
      end
    end
  end

  def apply(f, parser)
    lambda do |input|
      r = parse(parser, input)
      return r unless r.is_valid?

      STATE.new(result: f.call(r.result), rest: r.rest, is_valid?: r.is_valid?)
    end
  end

  def chain(f, parser)
    lambda do |input|
      r = parse(parser, input)
      return r unless r.is_valid?

      new_parser = f.call(r.result)
      parse(new_parser, r.rest)
    end
  end

  def lazy(parser_thunk)
    lambda do |input|
      parse(parser_thunk.call, input)
    end
  end

  def between(left, right, content)
    apply(->(r) { r[1] }, sequence(left, content, right))
  end

  def lit_digit(i)
    lambda do |input|
      if input[0].to_i == i
        STATE.new(result: i, rest: input[1..], is_valid?: true)
      else
        STATE.new(result: [], rest: input, is_valid?: false)
      end
    end
  end

  def any_char
    lambda do |input|
      if input[0]
        STATE.new(result: input[0], rest: input[1..], is_valid?: true)
      else
        STATE.new(result: [], rest: input, is_valid?: false)
      end
    end
  end

  def char_in(char_set)
    lambda do |input|
      if char_set.include?(input[0])
        STATE.new(result: input[0], rest: input[1..], is_valid?: true)
      else
        STATE.new(result: [], rest: input, is_valid?: false)
      end
    end
  end

  def str(word)
    lambda do |input|
      if input.start_with?(word)
        STATE.new(result: word, rest: input[word.size..], is_valid?: true)
      else
        STATE.new(result: [], rest: input, is_valid?: false)
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
  def between_brackets(content); between(str('['), str(']'), content) end
  def between_parentheses(content); between(str('('), str(')'), content) end
end

P = Parsing

def evaluate(node)
  case node.fetch(:type)
  when 'number' then node.fetch(:value)
  when 'operation'
    case node[:value][:op]
    when '+' then evaluate(node[:value][:a]) + evaluate(node[:value][:b])
    when '-' then evaluate(node[:value][:a]) - evaluate(node[:value][:b])
    when '*' then evaluate(node[:value][:a]) * evaluate(node[:value][:b])
    when '/' then evaluate(node[:value][:a]) / evaluate(node[:value][:b])
    end
  end
end

def expression
  P.lazy(-> { P.choice(number, operation) })
end

def number
  P.apply(
    ->(x) { { type: 'number', value: x } },
    P.integer
  )
end

def operation
  P.apply(
    ->((a, op, b)) { { type: 'operation', value: { op: op, a: a, b: b } } },
    P.between_parentheses(P.sequence(expression, P.char_in(['+', '-', '*', '/']), expression))
  )
end

p evaluate(P.parse(expression, '1989').result)
p evaluate(P.parse(expression, '(1+2)').result)
p evaluate(P.parse(expression, '((2+3)*5))').result)
p evaluate(P.parse(expression, '(((2+3)*5)-3)').result)
