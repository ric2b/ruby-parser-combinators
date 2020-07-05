require './basic_parsing.rb'
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
    P.token(P.integer)
  )
end

def operation
  P.apply(
    ->((a, op, b)) { { type: 'operation', value: { op: op, a: a, b: b } } },
    P.token(P.between_parentheses(P.sequence(P.token(expression), P.char_in(['+', '-', '*', '/']), P.token(expression))))
  )
end

p evaluate(P.parse(expression, ' 1989   ').result)
p evaluate(P.parse(expression, ' ( 1 + 2 ) ').result)
p evaluate(P.parse(expression, '( ( 2 + 3 ) * 5 ) )').result)
p evaluate(P.parse(expression, '( ( ( 2 + 3 ) * 5 ) - 13 )').result)
