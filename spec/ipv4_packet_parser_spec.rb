require './ipv4_packet_parser.rb'

describe "ipv4 packet parser" do
  context "with a given file" do
    let(:file_path) { 'packet.bin' }

    let(:packet_data) do
      {
        'Version' => 4,
        'IHL' => 5,
        'DCSP' => 0,
        'ECN' => 0,
        'Total Lenght' => 68,
        'Identification' => 44_299,
        'Flags' => 0,
        'Fragment Offset' => 0,
        'Time To Live' => 64,
        'Protocol' => 17,
        'Header Checksum' => 29_298,
        'Source IP Address' => [172, 20, 2, 253],
        'Destination IP Address' => [172, 20, 0, 6],
      }
    end

    it "calculates the correct value" do
      expect(IPv4Parser.parse_bin_file(file_path: file_path).result).to eq(packet_data)
    end
  end
end
