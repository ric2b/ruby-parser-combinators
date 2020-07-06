require './basic_parsing.rb'
P = Parsing

# Expr ::= Term ('+' Term | '-' Term)*
# Term ::= Factor ('*' Factor | '/' Factor)*
# Factor ::= ['-'] (Number | '(' Expr ')')
# Number ::= Digit+

module Calculator
  module_function

  def calculate(input)
    r = P.parse(expression, input)
    raise ArgumentError unless r.is_valid?

    evaluate(r.result)
  end

  private_class_method def num_node(x) { type: 'number', value: x }  end
  private_class_method def op_node(op, a ,b) { type: 'operation', value: { op: op, a: a, b: b } } end

  private_class_method def evaluate(node)
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

  private_class_method def expression
    P.apply(
      ->(r) { r[1].reduce(r[0]) { |a, (op, b)| op_node(op, a, b) } },
      P.sequence(P.token(term), P.many(P.sequence(P.char_in(['+', '-']), P.token(term)), at_least: 0)),
      )
  end

  private_class_method def term
    P.apply(
      ->(r) { r[1].reduce(r[0]) { |a, (op, b)| op_node(op, a, b) } },
      P.sequence(P.token(factor), P.many(P.sequence(P.char_in(['*', '/']), P.token(factor)), at_least: 0)),
      )
  end

  private_class_method def factor
    P.lazy(-> { P.choice(number, P.between_parentheses(expression)) })
  end

  private_class_method def number
    P.apply(method(:num_node), P.token(P.integer))
  end
end
