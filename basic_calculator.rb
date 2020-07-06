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

# Expr ::= Term ('+' Term | '-' Term)*
# Term ::= Factor ('*' Factor | '/' Factor)*
# Factor ::= ['-'] (Number | '(' Expr ')')
# Number ::= Digit+

def expression
  P.apply(
    ->(r) { r[1].reduce(r[0]) { |a, (op, b)| { type: 'operation', value: { op: op, a: a, b: b } } } },
    P.sequence(P.token(term), P.many(P.sequence(P.char_in(['+', '-']), P.token(term)), at_least: 0)),
  )
end

def term
  P.apply(
    ->(r) { r[1].reduce(r[0]) { |a, (op, b)| { type: 'operation', value: { op: op, a: a, b: b } } } },
    P.sequence(P.token(factor), P.many(P.sequence(P.char_in(['*', '/']), P.token(factor)), at_least: 0)),
  )
end

def factor
  P.lazy(-> { P.choice(number, P.between_parentheses(expression)) })
end

def number
  P.apply(
    ->(x) { { type: 'number', value: x } },
    P.token(P.integer)
  )
end

p evaluate(P.parse(expression, '1989').result)
p evaluate(P.parse(expression, '(1989)').result)
p evaluate(P.parse(expression, '1+2').result)
p evaluate(P.parse(P.until_end(expression), '1+2*3').result)
p evaluate(P.parse(expression, '(1+2)*3').result)
p evaluate(P.parse(expression, '(1+2)*3-1*2').result)
p evaluate(P.parse(expression, '( ( 2 + 3 ) * 5 ) )').result)
p evaluate(P.parse(expression, '((( 2 + 3) *5)- 13 )').result)
