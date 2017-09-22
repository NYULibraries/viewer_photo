require 'rest_client'
require 'json'
class GetRsbeInfo
  attr_reader :rsbe_hsh
  def initialize(coll_path, user, pass)
    unless File.exist?(coll_path)
      LOG.error("#{@coll_path} must exist") 
    end
    @coll_path = coll_path
    @user = user
    @pass = pass
    @rsbe_hsh = get_collection
  end

  private
  def get_collection
    coll_info = {}
    p @coll_path
    begin
      @coll_url = File.read(@coll_path)
    rescue Exception => e
      LOG.error(e)
      caller.each { |c|
       LOG.error(c)
      }
    end
    @coll_url.chomp!
    url = parse_url(@coll_url)
    rsp,status = get(url)
    if status
      rsbe_info = JSON.parse(rsp.body)
      partner_info = get_partner(rsbe_info["partner_url"])
      if partner_info.nil?
        LOG.error("Missing partner info") if partner_info.nil?
      else
        coll_info = {:coll_code => rsbe_info["code"],
          :coll_name => rsbe_info["name"],
          :coll_identifier => rsbe_info["id"],
          :partner_code => partner_info["code"],
          :partner_name => partner_info["name"],
          :partner_id => rsbe_info["partner_id"]
        }
      end
    else
      LOG.error("Missing collection info")
    end
    coll_info
  end

  def get_partner(url)
    partner = nil
    url = parse_url(url)
    partner_info,status = get(url)
    partner = JSON.parse(partner_info.body) if status
    partner
  end
  def parse_url(url)
    request = url.split("https://")
    "https://#{request[0]}#{@user}:#{@pass}@#{request[1]}"
  end
  def get(url)
    status = false
    begin
      rsp = RestClient.get(url, {accept: :json})
      status = true
    rescue Exception => e
      LOG.error("#{e.to_s} for #{url}")
    end
    [rsp,status]
  end
end
