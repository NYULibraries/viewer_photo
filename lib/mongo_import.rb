require 'mongo'
include Mongo

class ImportMongo
  URL_PREFIX = "mongodb://"
  def self.import(dir:,url:, photo_pg_hsh:,config:)
    success = false
    @error_msg = []
    @mongo_url = url
    @dir = dir
    @photo_pages = photo_pg_hsh
    @config = config
    @mongo_config = {}
    chk = chk_config
    if chk
      @mongo_config = get_mongo_path
    else
      @error_msg << "#{@config} must exist"
    end
    unless @mongo_config.empty?
      @client = connect_mongo
      @photos = find_photo
      import_photos
    end
    @error_msg.each { |e|
      LOG.error(e)
    }
    success = true if @error_msg.size == 0
    success
  end

  def self.get_mongo_path
    mongo_config = {}
    begin
      File.foreach(@config) { |line|
        line.chomp!
        unless line =~ /=/
          @error_msg << "#{@config} entry must have a delimiter of '='\n"
          caller.each { |c|
            @error_msg << c
          }
        end
        key,value = line.split("=")
        unless validate_config.include?(key)
          @error_msg << "#{validate_config} should be the keys in #{@config} file"
        end
        if value.nil?
          @error_msg << "value can not be nil"
        end
        mongo_config[key] = value
      }
      mongo_config["MONGO_URL"] = URL_PREFIX + @mongo_url
    rescue Exception => e
      @error_msg << e
    end
    mongo_config
  end

  def self.find_photo
    begin
      @client[:"#{@mongo_config["MONGO_COLL"]}"].find(:isPartOf => "#{@dir}")
    rescue Exception => e
      @error_msg << e.message
    end
  end

  def self.import_photos
    if @photos.count > 0
      begin
        @photos.delete_many
      rescue Exception => err
        @error_msg << err
      end
    end
    begin
      @client[:"#{@mongo_config["MONGO_COLL"]}"].insert_many(@photo_pages)
    rescue Exception => err
      @error_msg << err
    end
  end

  def self.connect_mongo
    begin
      Mongo::Client.new(@mongo_config["MONGO_URL"])
    rescue Exception => e
      @error_msg << e.message
    end
  end

  def self.validate_config
    ["MONGO_COLL"]
  end

  def self.chk_config
    chk = false
    chk = true if File.exist?(@config)
    chk
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
