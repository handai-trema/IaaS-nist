$LOAD_PATH.unshift File.join(__dir__, '../vendor/topology/lib')

require 'active_support/core_ext/module/delegation'
require 'optparse'
require 'path_in_slice_manager'
require 'path_manager'
require 'topology_controller'
require 'pio'


# L2 routing switch　+ 
class RoutingSwitch < Trema::Controller
  # Command-line options of RoutingSwitch
  class Options
    attr_reader :slicing

    def initialize(args)
      @opts = OptionParser.new
      @opts.on('-s', '--slicing') { @slicing = true }
      @opts.parse [__FILE__] + args
    end
  end

  timer_event :flood_lldp_frames, interval: 1.sec
  timer_event :send_message_flowstatsrequest, interval: 20.sec

  delegate :flood_lldp_frames, to: :@topology

  @byte_threshold = 1000;

  def slice
    fail 'Slicing is disabled.' unless @options.slicing
    Slice
  end

  def start(args)
    @options = Options.new(args)
    @path_manager = start_path_manager
    @topology = start_topology
    logger.info 'Routing Switch started.'
  end

  delegate :switch_ready, to: :@topology
  delegate :features_reply, to: :@topology
  delegate :switch_disconnected, to: :@topology
  delegate :port_modify, to: :@topology

  def packet_in(dpid, packet_in)
    @dpid4 = 0x4
    @topology.packet_in(dpid, packet_in)
    @path_manager.packet_in(dpid, packet_in) unless packet_in.lldp?
=begin
    # debug for contoroller packet out
    if dpid.to_hex == "0x4" then
      @dpid4 = dpid
    end
      data = [200]
      puts " * byte_count_binary #{dpid}: #{data.pack('Q*')}"
      #if byte_stats!=0 then
        puts "send_packet_out debug #{@dpid4}"
        actions = [
               SetDestinationMacAddress.new('08:00:27:74:6d:e1'),
               #SetDestinationMacAddress.new('20:c6:eb:0d:ac:68'),
               SetSourceMacAddress.new('11:22:33:44:55:66'),
               SendOutPort.new(:flood)]
        send_packet_out(
          @dpid4,
          raw_data: data.pack('Q*'),
          #raw_data: Parser::IPv4Packet.new(#transport_source_port: 2,
                                         #destination_ip_address: '192.168.1.3'
                                         #transport_destination_port: 1,
                                         #rest: byte_stats
                                         #),
          actions: actions)
      #end
=end
  end

  def flow_stats_reply(dpid, message)
    logger.info "receive FlowStatsReply : Switch #{dpid.to_hex} #{message.stats_type} stats"
    puts "start------------------------------------------"
    message.stats.each do |each|
      each.actions.each do |action|
        puts "  * actions: #{action.to_s}"
      end
      puts "  * match: #{each.match.to_s}"
      puts "  * packet_count: #{each.packet_count}"
      puts "  * byte_count: #{each.byte_count}"
      if each.byte_count>10000 then
        puts "byte count over 10000"
        # DoS 対策実行箇所
        #Slice.destroy("slice_default")
      end
      byte_stats = each.byte_count
      data = [each.byte_count]
      puts " * byte_count_binary: #{data.pack('Q*')}"
      if byte_stats!=0 then
        puts "send_packet_out byte_count of #{dpid.to_hex}"
        actions = [
               SetDestinationMacAddress.new('08:00:27:74:6d:e1'),
               SendOutPort.new(11)]
        send_packet_out(
          dpid,
          raw_data: data.pack('Q*'),
          #raw_data: Parser::IPv4Packet.new(#destination_ip_address: '192.168.1.100'
                                         #transport_destination_port: 1,
                                         #rest: byte_stats
                                         #),
          actions: actions)
      end
      puts "-----------------------------------------------"
    end
=begin
    puts "send_packet_out stats"
    actions = [
               SetDestinationMacAddress.new('33:33:33:33:33:33'),
               SendOutPort.new(2)]
    send_packet_out(
      dpid,
      raw_data: message.stats.to_binary_s,
      actions: actions)
=end

  end

  private


  def start_path_manager
    fail unless @options
    (@options.slicing ? PathInSliceManager : PathManager).new.tap(&:start)
  end

  def start_topology
    fail unless @path_manager
    TopologyController.new { |topo| topo.add_observer @path_manager }.start
  end

  def send_message_flowstatsrequest 
      puts "end============================================"
      puts "send FlowStatsRequest"
      puts "Start=========================================="
      send_message 0x4, Pio::FlowStats::Request.new(:match => Match.new())
  end



end
