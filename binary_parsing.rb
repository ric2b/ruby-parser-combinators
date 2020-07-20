require './basic_parsing.rb'
P = Parsing

module BinaryParser
  module_function

  def parse(parser, input)
    P.parse(parser, input.unpack('B*').join)
  end

  def bit(value: nil)
    lambda do |input|
      if input[0] && value.nil? || input[0] == value
        P::STATE.new(result: input[0], rest: input[1..], is_valid?: true)
      else
        P::STATE.new(result: nil, rest: input, is_valid?: false)
      end
    end
  end

  def zero; bit(value: '0') end
  def one; bit(value: '1') end

  def uint(n)
    P.apply(->(bits) { bits.join.to_i(2) }, P.sequence(*Array.new(n) { bit }))
  end

  def int(n)
    P.apply(
      ->(bits) { bits[1..].join.to_i(2) - (bits[0].to_i * 2**(bits.size - 1)) },
      P.sequence(*Array.new(n) { bit })
    )
  end

  def ascii_str(s)
    P.chain(
      ->(r) { r == s ? P.succeed(r) : P.fail },
      P.apply(->(chars) { chars.map(&:chr).join }, P.sequence(*Array.new(s.size) { uint(8) }))
    )
  end
end
