# Routing table
class RoutingTable
  include Pio

  MAX_NETMASK_LENGTH = 32

  def initialize(route)
    @db = Array.new(MAX_NETMASK_LENGTH + 1) { Hash.new }
    route.each { |each| add(each) }
  end

  def add(options)
    netmask_length = options.fetch(:netmask_length)
    prefix = IPv4Address.new(options.fetch(:destination)).mask(netmask_length)
    @db[netmask_length][prefix.to_i] = IPv4Address.new(options.fetch(:next_hop))
  end

  def delete(options)
    netmask_length = options.fetch(:netmask_length)
    prefix = IPv4Address.new(options.fetch(:destination)).mask(netmask_length)
    @db[netmask_length].delete(prefix.to_i)
  end

  def lookup(destination_ip_address)
    MAX_NETMASK_LENGTH.downto(0).each do |each|
      prefix = destination_ip_address.mask(each)
      entry = @db[each][prefix.to_i]
      return entry if entry
    end
    nil
  end

  def show
    entries = []
    entries.push("dst/mask, nexthop")
    entries.push("=================")
    MAX_NETMASK_LENGTH.downto(0).each do |each|
      @db[each].each do |k, v|
        entries.push("#{IPAddr.new(k, Socket::AF_INET).to_s}/#{each}, #{v.to_s}")
      end
    end
    entries.push("")
    return entries
  end
end
