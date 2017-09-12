require 'mongo'
include Mongo

class ImportMongo
  URL_PREFIX = "mongodb://"
  def self.import(dir:,url:, photo_pg_hsh:,config:)
    @mongo_url = url
    @dir = dir
    @photo_pages = photo_pg_hsh
    @config = config
    @mongo_config = get_mongo_path
    @client = connect_mongo
    coll_exist =  chk_collection_existence
    if chk_collection_existence
      @photos = find_photo
      import_photos
    else
       raise RuntimeError, "Collection: #{@mongo_config["MONGO_COLL"]} doesn't exist"
    end
  end

  def self.get_mongo_path
    mongo_config = {}
    File.foreach(@config) { |line|
      line.chomp!
      unless line =~ /=/
       raise RuntimeError, "#{@config} entry must have a delimiter of '='\n"
      end
      key,value = line.split("=")
      unless validate_config.include?(key)
       raise RuntimeError, "#{validate_config} should be the keys in #{@config} file\n"
      end
      if value.nil?
       raise RuntimeError, "value can not be nil\n"
      end
      mongo_config[key] = value
    }
    mongo_config["MONGO_URL"] = URL_PREFIX + @mongo_url
    mongo_config
  end

  def self.find_photo
    begin
      @client[:"#{@mongo_config["MONGO_COLL"]}"].find(:isPartOf => "#{@dir}")
    rescue Exception => e
      puts e.message
    end
  end

  def self.import_photos
    if @photos.count > 0
      @photos.delete_many
    end
    @client[:"#{@mongo_config["MONGO_COLL"]}"].insert_many(@photo_pages)
  end

  def self.connect_mongo
    begin
     Mongo::Client.new(@mongo_config["MONGO_URL"])
    rescue Exception => e
      puts e.message
    end
  end

  def self.validate_config
    ["MONGO_COLL"]
  end

  def self.chk_config
    unless File.exist?(@config)
     raise RuntimeError, "#{@config} must exist\n"
    end
  end

  def self.chk_collection_existence
    exist = false
    collections = []
    db_name = @client.database.name
    @client.collections.each { |c|
      collections << c.namespace
    }
    collections = collections.map { |c| c.sub("#{db_name}.","") }
    if collections.include?(@mongo_config["MONGO_COLL"])
      exist = true
    end
    exist
  end
  private_class_method :chk_collection_existence, :chk_config, :connect_mongo, :import_photos, :find_photo, :get_mongo_path
end
