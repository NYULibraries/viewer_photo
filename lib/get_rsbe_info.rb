require 'rest_client'
require 'json'
class GetRsbeInfo
  attr_reader :rsbe_info
  def initialize(coll_path, user, pass)
    unless File.exist?(coll_path)
      raise RuntimeError, "#{coll_path} must exist"
    end
    @coll_path = coll_path
    @user = user
    @pass = pass
    @rsbe_info = get_collection
  end

  private
  def get_collection
    coll_info = {}
    @coll_url = File.read(@coll_path)
    @coll_url.chomp!
    url = parse_url(@coll_url)
    rsp = get(url)
    rsbe_info = JSON.parse(rsp.body)
    partner_info = get_partner(rsbe_info["partner_url"])
    coll_info = {:coll_code => rsbe_info["code"],
                 :coll_name => rsbe_info["name"],
                 :partner_code => partner_info["code"],
                 :partner_name => partner_info["name"]
    }
  end

  def get_partner(url)
    url = parse_url(url)
    partner_info = get(url)
    partner = JSON.parse(partner_info.body)
    partner
  end
  def parse_url(url)
    request = url.split("https://")
    "https://#{request[0]}#{@user}:#{@pass}@#{request[1]}"
  end
  def get(url)
    begin
      rsp = RestClient.get(url, {accept: :json})
    rescue Exception => e
      raise RuntimeError, e
    end
    rsp
  end
end
