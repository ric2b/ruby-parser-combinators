require './basic_parsing.rb'
P = Parsing

describe "basic parsing" do
  describe "string matching" do
    let(:parser) { P.str(match) }

    where(:input, :match, :result) do
      [
        ['hello', 'h', 'h'],
        ['hello', 'z', []],
      ]
    end

    with_them do
      it "works" do
        expect(P.parse(parser, input).result).to eq(result)
      end
    end
  end

  describe "choice" do
    it "works" do
      expect(P.parse(P.choice(P.str('e'), P.str('h')), 'hello').result).to eq('h')
    end
  end

  describe "sequence" do
    it "works" do
      expect(P.parse(P.sequence(P.str('h'), P.str('e')), 'hello').result).to eq(['h', 'e'])
    end
  end

  describe "between" do
    it "works" do
      expect(P.parse(P.between(P.str('('), P.letters, P.str(')')), '(hello)').result).to eq('hello')
    end
  end

  describe "many" do
    it "works" do
      expect(P.parse(P.many(P.str('h')), 'hhhhhee').result).to eq(['h', 'h', 'h', 'h', 'h'])
    end

    it "works for digits" do
      expect(P.parse(P.many(P.digit), '12345').result).to eq(['1', '2', '3', '4', '5'])
    end
  end

  describe "apply" do
    it "works" do
      expect(P.parse(P.apply(lambda { |s| s.map(&:upcase) }, P.many(P.str('h'))), 'hhhhhee').result).to eq(['H', 'H', 'H', 'H', 'H'])
      expect(P.parse(P.apply(->(x) { x.upcase }, P.str('hello')), 'hello world').result).to eq('HELLO')
    end
  end

  describe "chain" do
    let(:stringParser) { P.apply(->(r) { { type: 'string', value: r } }, P.letters) }
    let(:numberParser) { P.apply(->(r) { { type: 'number', value: r } }, P.digits) }
    let(:dicerollParser) { P.apply(->((a, _, b)) { { type: 'diceroll', value: [a, b] } }, P.sequence(P.integer, P.str('d'), P.integer)) }
    let(:typeExtractor) do
      P.apply(
        ->(r) { r[0] },
        P.sequence(P.choice(P.str('string'), P.str('number'), P.str('diceroll')), P.str(':'))
      )
    end
    let(:parserChooser) do
      lambda do |type|
        case type
        when 'string' then stringParser
        when 'number' then numberParser
        when 'diceroll' then dicerollParser
        end
      end
    end

    it "works" do
      expect(P.parse(P.chain(parserChooser, typeExtractor), 'diceroll:2d8').result).to eq({ type: 'diceroll', value: [2, 8] })
    end
  end

  describe "lazy" do
    it "works" do
      def value
        P.lazy(-> { P.choice(P.integer, array) })
      end

      def array
        P.between(P.str('['), P.sep_by(P.str(','), value), P.str(']'))
      end

      expect(P.parse(array, '[12,[4,4],65,7]').result).to eq([12, [4, 4], 65, 7])
    end
  end

  describe "sep by" do
    it "works" do
      expect(P.parse(P.sep_by(P.str(','), P.digits), '1,2,34,5,7').result).to eq(['1', '2', '34', '5', '7'])
    end
  end

  describe "any char" do
    it "works" do
      expect(P.parse(P.many(P.any_char), 'hello    world2').result).to eq(["h", "e", "l", "l", "o", " ", " ", " ", " ", "w", "o", "r", "l", "d", "2"])
    end
  end

  describe "letters" do
    it "works" do
      expect(P.parse(P.letters, 'hello world').result).to eq('hello')
    end
  end

  describe "integer" do
    it "works" do
      expect(P.parse(P.integer, '12345').result).to eq(12345)
    end
  end

  describe "end of input" do
    it "works" do
      expect(P.parse(P.sequence(P.digits, P.end_of_input), '12').result).to eq(['12', []])
    end
  end

  describe "whitespace" do
    it "works" do
      expect(P.parse(P.sequence(P.letters, P.whitespace, P.letters), 'hello world 2').result).to eq(['hello', ' ', 'world'])
    end
  end
end
