
require 'command_line'
require 'topology'

# This controller collects network topology information using LLDP.
class TopologyController < Trema::Controller
  timer_event :flood_lldp_frames, interval: 1.sec

  attr_reader :topology

  def initialize(&block)
    super
    @command_line = CommandLine.new(logger)
    @topology = Topology.new
    @arp_table = Hash.new
    block.call self
  end

  def start(args = [])
    @command_line.parse(args)
    @topology.add_observer @command_line.view
    logger.info "#{@command_line.view}"
    logger.info "Topology started! (#{@command_line.view})."
    self
  end

  def add_observer(observer)
    @topology.add_observer observer
  end

  def switch_ready(dpid)
    send_message dpid, Features::Request.new
  end

  def features_reply(dpid, features_reply)
    @topology.add_switch dpid, features_reply.physical_ports.select(&:up?)
  end

  def switch_disconnected(dpid)
    puts "switch_disconnected #{dpid}"
    @topology.delete_switch dpid
  end

  def port_modify(_dpid, port_status)
    updated_port = port_status.desc
    return if updated_port.local?
    if updated_port.down?
      @topology.delete_port updated_port
    elsif updated_port.up?
      @topology.add_port updated_port
    else
      fail 'Unknown port status.'
    end
  end

  def packet_in(dpid, packet_in)
    if packet_in.lldp?
      @topology.maybe_add_link Link.new(dpid, packet_in)
    elsif packet_in.data.is_a? Arp
      puts "ARP packet in"
      puts packet_in.source_mac
      @topology.maybe_add_host(packet_in.source_mac,
                               packet_in.sender_protocol_address,
                               dpid,
                               packet_in.in_port)
    elsif packet_in.data.is_a? Pio::Arp::Request
      arp_request = packet_in.data
      unless @arp_table.include?(arp_request.sender_protocol_address.to_s) then
        @arp_table.store(arp_request.sender_protocol_address.to_s,packet_in.source_mac)
        puts "ARP Table is added!!"
        puts @arp_table
      end
      if @arp_table.include?(arp_request.target_protocol_address.to_s) then
        puts "send ARP reply packet!!"
        send_packet_out(
          dpid,
          raw_data: Arp::Reply.new(
            destination_mac: arp_request.source_mac,
            source_mac:@arp_table[arp_request.target_protocol_address.to_s],
            sender_protocol_address: arp_request.target_protocol_address,
            target_protocol_address: arp_request.sender_protocol_address
          ).to_binary,
          actions: SendOutPort.new(packet_in.in_port)
        )
      else
        @topology.ports.each do |dpid,ports|
          ports.each do |port|
            flag = false
            @topology.links.each do |link|
              if (link.dpid_a == dpid && link.port_a == port.port_no) || (link.dpid_b == dpid && link.port_b == port.port_no) then
                flag = true
                break
              end
            end
            if !flag then
              send_packet_out(
                dpid,
                raw_data: packet_in.raw_data,
                actions: SendOutPort.new(port.port_no)
              )
            end
          end
        end
      end
    elsif packet_in.data.is_a? Pio::Arp::Reply
      arp_reply = packet_in.data
      unless @arp_table.include?(arp_reply.sender_protocol_address.to_s) then
        @arp_table.store(arp_reply.sender_protocol_address.to_s,packet_in.source_mac)
        puts "ARP Table is added!!"
        puts @arp_table
      end
        @topology.ports.each do |dpid,ports|
          ports.each do |port|
            flag = false
            @topology.links.each do |link|
              if (link.dpid_a == dpid && link.port_a == port.port_no) || (link.dpid_b == dpid && link.port_b == port.port_no) then
                flag = true
                break
              end
            end
            if !flag then
              send_packet_out(
                dpid,
                raw_data: packet_in.raw_data,
                actions: SendOutPort.new(port.port_no)
              )
            end
          end
        end
    elsif packet_in.data.is_a? Parser::IPv4Packet
      if packet_in.source_ip_address.to_s != "0.0.0.0"
        #unless packet_in.source_ip_address.to_a[3] > 100 then
          @topology.maybe_add_host(packet_in.source_mac,
                                   packet_in.source_ip_address,
                                   dpid,
                                   packet_in.in_port)
          #puts "host is registered by Parser::IPv4Packet"
        #end
      end
    else
      p packet_in.ether_type.to_hex
    end
  end

  def flood_lldp_frames
    @topology.ports.each do |dpid, ports|
      send_lldp dpid, ports
    end
  end

  private

  def send_lldp(dpid, ports)
    ports.each do |each|
      port_number = each.number
      send_packet_out(
        dpid,
        actions: SendOutPort.new(port_number),
        raw_data: lldp_binary_string(dpid, port_number)
      )
    end
  end

  def lldp_binary_string(dpid, port_number)
    destination_mac = @command_line.destination_mac
    if destination_mac
      Pio::Lldp.new(dpid: dpid,
                    port_number: port_number,
                    destination_mac: destination_mac).to_binary
    else
      Pio::Lldp.new(dpid: dpid, port_number: port_number).to_binary
    end
  end
end
