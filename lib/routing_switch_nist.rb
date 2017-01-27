$LOAD_PATH.unshift File.join(__dir__, '../vendor/topology/lib')

require 'active_support/core_ext/module/delegation'
require 'optparse'
require 'path_in_slice_manager'
require 'path_manager'
require 'topology_controller'


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
  timer_event :send_message_flowstatsrequest, interval: 10.sec

  delegate :flood_lldp_frames, to: :@topology

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
=begin
  def switch_ready dpid
    puts "#{dpid.to_hex}が起動しました"
    @dpid=dpid
  end
=end
  delegate :switch_ready, to: :@topology
  delegate :features_reply, to: :@topology
  delegate :switch_disconnected, to: :@topology
  delegate :port_modify, to: :@topology

  def packet_in(dpid, packet_in)
    @topology.packet_in(dpid, packet_in)
    @path_manager.packet_in(dpid, packet_in) unless packet_in.lldp?
  end

  def flow_stats_reply(dpid, message)
    logger.info "Switch #{dpid.to_hex} stats_type = #{message.stats_type}"
    logger.info "Switch #{dpid.to_hex} stats = #{message.stats}"
=begin
    send_packet_out(
      dpid,
      #raw_data: message.raw_data,
      raw_data: message.stats,
      actions: SendOutPort.new(11))
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
      puts "send FlowStatsRequest"
      send_message 0x5, Pio::FlowStats::Request.new(:match => Match.new())
  end



end
