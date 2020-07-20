require './basic_parsing.rb'
require './binary_parsing.rb'
P = Parsing
B = BinaryParser

describe "binary parsing" do
  describe "reading bits" do
    it "reads correctly" do
      File.open('test.bin', mode: 'wb') do |file|
        file.write([234].pack('C*'))
      end

      File.open('test.bin', mode: 'rb') do |file|
        result = file.read.unpack('C*')
        expect(result).to eq([234])
      end
    end

    it "reads any bit" do
      r = B.parse(B.bit, [0].pack('C'))
      expect(r.is_valid?).to be_truthy
      expect(r.result).to eq('0')
    end

    it "reads a zero" do
      r = B.parse(B.zero, [0].pack('C'))
      expect(r.is_valid?).to be_truthy
      expect(r.result).to eq('0')
    end

    it "reads a one" do
      r = B.parse(B.one, ['10000000'.to_i(2)].pack('C'))
      expect(r.is_valid?).to be_truthy
      expect(r.result).to eq('1')
    end

    it "reads many ones" do
      r = B.parse(P.many(B.one), ['11100000'.to_i(2)].pack('C'))
      expect(r.is_valid?).to be_truthy
      expect(r.result).to eq(['1', '1', '1'])
    end

    it "reads uints correctly" do
      r = B.parse(B.uint(8), ['11100000'.to_i(2)].pack('C'))
      expect(r.is_valid?).to be_truthy
      expect(r.result).to eq('11100000'.to_i(2))
    end

    it "reads ints correctly" do
      r = B.parse(B.int(8), [-96].pack('c*'))
      expect(r.is_valid?).to be_truthy
      expect(r.result).to eq(-96)
    end

    it "reads sub-ints correctly" do
      r = B.parse(P.sequence(B.uint(4), B.uint(4)), [234].pack('c*'))
      expect(r.is_valid?).to be_truthy
      expect(r.result).to eq([14, 10])
    end

    it "reads super-ints correctly" do
      r = B.parse(B.uint(16), [234, 235].pack('c*'))
      expect(r.is_valid?).to be_truthy
      expect(r.result).to eq(60139)
    end

    it "reads ascii strings correctly" do
      r = B.parse(B.ascii_str('Hello World!'), ['Hello World!'].pack('a*'))
      expect(r.is_valid?).to be_truthy
      expect(r.result).to eq('Hello World!')
    end
  end
end
