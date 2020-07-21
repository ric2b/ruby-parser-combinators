require './basic_parsing.rb'
require './binary_parsing.rb'
P = Parsing
B = BinaryParser

module IPv4Parser
  module_function

  def parse_packet(input)
    B.parse(
      P.chain(
        ->(packet_data) { packet_data['IHL'] > 5 ? P.apply(tag('Options'), B.uint(32 * (packet_data['IHL'] - 5))) : P.succeed(packet_data) },
        P.apply(
          ->(sections) { sections.to_h },
          P.sequence(
            P.apply(tag('Version'), B.uint(4)),
            P.apply(tag('IHL'), B.uint(4)),
            P.apply(tag('DCSP'), B.uint(6)),
            P.apply(tag('ECN'), B.uint(2)),
            P.apply(tag('Total Lenght'), B.uint(16)),
            P.apply(tag('Identification'), B.uint(16)),
            P.apply(tag('Flags'), B.uint(3)),
            P.apply(tag('Fragment Offset'), B.uint(13)),
            P.apply(tag('Time To Live'), B.uint(8)),
            P.apply(tag('Protocol'), B.uint(8)),
            P.apply(tag('Header Checksum'), B.uint(16)),
            P.apply(tag('Source IP Address'), P.sequence(*Array.new(4) { B.uint(8) })),
            P.apply(tag('Destination IP Address'), P.sequence(*Array.new(4) { B.uint(8) })),
          )
        )
      ),
      input
    )
  end

  def parse_bin_file(file_path:)
    parse_packet(File.read(file_path, mode: 'rb'))
  end

  def tag(type)
    lambda do |result|
      [type, result]
    end
  end
end
