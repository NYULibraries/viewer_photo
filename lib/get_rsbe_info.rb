class GetRsbeInfo
  def initialize(coll_path)
    unless File.exist?(coll_path)
      raise RuntimeError, "#{coll_path} must exist"
    end
    @coll_url = File.read(coll_path)
  end

  def get_collection
    @coll_url = File.read(coll_path)
  end
end
