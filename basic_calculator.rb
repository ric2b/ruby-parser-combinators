STEP_OUTPUT = Struct.new(:parsed, :rest, keyword_init: true)

class ParseError < ArgumentError
end

def parse(parse_step, input)
    parse_step.call(input)
end

SOME = lambda do |parse_step, input|
    accum = ''
    rest = input
    step_output = STEP_OUTPUT.new(parsed: '', rest: input)
    loop do
        step_output = parse(parse_step, rest)

        break if step_output.rest == rest
        accum += step_output.parsed
        rest = step_output.rest
    end
    STEP_OUTPUT.new(parsed: accum, rest: step_output.rest)
rescue ParseError
    raise ParseError if accum == ''
    STEP_OUTPUT.new(parsed: accum, rest: step_output.rest)
end

CHOICE = lambda do |parse_step_a, parse_step_b, input|
    return parse(parse_step_a, input)
rescue ParseError
    parse(parse_step_b, input)
rescue ParseError
    STEP_OUTPUT.new(parsed: '', rest: input)
end

PARSE_CHAR_IF = lambda do |satisfies, input|
    if satisfies.call(input[0] || '')
        STEP_OUTPUT.new(parsed: input[0] || '', rest: input[1..] || '')
    else
        raise ParseError.new(input)
    end
rescue TypeError, ArgumentError
    raise ParseError.new(input)
end

DIGIT = PARSE_CHAR_IF.curry[method(:Integer)]
CHAR = lambda { |expected_char| PARSE_CHAR_IF.curry[lambda { |c| c == expected_char }] }
INT = lambda do |input| 
    step_output = SOME.call(DIGIT, input)
    STEP_OUTPUT.new(parsed: Integer(step_output.parsed), rest: step_output.rest)
rescue
    raise ParseError.new(input)
end    

def expression_parser(input)
    x, rest = *parse(INT, input)
    _, rest = *parse(CHAR['+'], rest)
    y, rest = *parse(INT, rest)
    return x + y
    #STEP_OUTPUT.new(parsed: '', rest: "#{x+y}#{rest}")
end

EXPRESSION = CHOICE.curry[method(:expression_parser), TERM]

def term(input)
    x, rest = *parse(INT, input)
    _, rest = *parse(CHAR['*'], rest)
    y, rest = *parse(INT, rest)
    return x * y
    #STEP_OUTPUT.new(parsed: '', rest: "#{x*y}#{rest}")
end

TERM = CHOICE.curry[method(:term), FACTOR]

def factor(input)
    _, rest = *parse(CHAR['('], input)
    x, rest = *parse(EXPRESSION, rest)
    _, rest = *parse(CHAR[')'], rest)
    return x
    #STEP_OUTPUT.new(parsed: '', rest: input)
end

FACTOR = CHOICE.curry[method(:factor), INT]

