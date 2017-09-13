require 'rest_client'

class GetRsbeInfo
  def initialize(coll_path, user, pass)
    unless File.exist?(coll_path)
      raise RuntimeError, "#{coll_path} must exist"
    end
    @coll_url = File.read(coll_path)
    @user = user
    @pass = pass
  end

  def get_collection
    @coll_url = File.read(coll_path)
    #rsp = RestClient.get()
  end
end
