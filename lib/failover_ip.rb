
require "json"
require "httparty"
require "lib/hooks"
require "hashr"

class FailoverIp
  attr_accessor :base_url, :failover_ip, :ping_ip, :ips, :interval, :timeout, :tries, :url_without_auth, :username, :password

  def ping(ip = ping_ip)
    `ping -W #{timeout} -c #{tries} #{ip}`

    $?.success?
  end

  def up?
    ping
  end

  def down?
    !ping
  end

  def current_target
#    response = RestClient.get("#{base_url}/failover/#{failover_ip}")
	HTTParty.get("#{url_without_auth}/failover/#{failover_ip}/", {:basic_auth=>{:username=>username,:password=>password}}).parsed_response["failover"]["active_server_ip"]

#   JSON.parse(response).deep_symbolize_keys[:failover][:active_server_ip]
  rescue Exception => e
    $logger.error "Unable to retrieve the active server ip. Exception #{e.message}"

    nil
  end

  def current_ping
    res = ips.detect { |ip| ip[:target] == current_target }

    return res[:ping] if res

    nil
  end

  def next_ip(target = current_target)
    if index = ips.index { |ip| ip[:target] == target }
      (ips.size - 1).times do |i|
        ip = ips[(index + i + 1) % ips.size]

        return ip if ping(ip[:ping])
      end
    end

    $logger.error "No more ip's available."

    nil
  end

  def switch_ips
    if new_ip = next_ip
      $logger.info "Switching to #{new_ip[:target]}."

      old_target = current_target

#      RestClient.post "#{base_url}/failover/#{failover_ip}", :active_server_ip => new_ip[:target]
	  HTTParty.post("#{url_without_auth}/failover/#{failover_ip}/", {:basic_auth=>{:username=>username,:password=>password}, :body=>{:active_server_ip=>new_ip[:target]}})
	   
	    

      Hooks.run failover_ip, old_target, new_ip[:target]

      return true
    end

    false
  rescue Exception => e
    $logger.error "Unable to set a new active server ip. Exception #{e.message}"

    false
  end

  def initialize(options)
    self.base_url = options[:base_url]
    self.failover_ip = options[:failover_ip]
    self.ping_ip = options[:ping_ip]
    self.ips = options[:ips]
    self.interval = options[:interval] || 30
    self.timeout = options[:timeout] || 10
    self.tries = options[:tries] || 3
    base_url =~ /^https:\/\/([\w\W]*):([\w\W]*)@([\w\W]*)$/
    self.url_without_auth = "https://#{$3}"
    self.username = $1
    self.password = $2
  end

  def check
    if down?
      $logger.info "#{ping_ip} is down."

      current = current_ping

      if ping_ip == current
        switch_ips
      else
        $logger.info "Not responsible for #{current}."
      end

      false
    else
      $logger.info "#{ping_ip} is up."

      true
    end
  end

  def monitor
    loop do
      check ? sleep(interval) : sleep(300)
    end
  end
end

