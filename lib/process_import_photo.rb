class ProcessImportPhoto
  def self.run(options = {})
    @error_msg = []
    validate_args(options)
    if @error_msg.count > 0
      raise RuntimeError, "errors found: #{@error_msg}"
    else
      set_instance_vars(options)
      process_import
    end
  end

  # meta programming because too lazy to
  # hand type all var names
  def self.set_instance_vars(options)
    options.each_pair { |k,v|
        instance_variable_set("@#{k}",v)
    }
  end
  def self.validate_args(options)
    chk_options_keys(options)
    chk_required_values(options)
  end

  def self.chk_options_keys(options)
    status = true
    unless options.keys.sort == required_keys.sort
      @error_msg << "#{required_keys.join(", ")} must be arguments"
      status = false
    end

    options.keys.each { |o|
      unless required_keys.include?(o)
        status = false
        @error_msg << "#{options.keys} must match #{required_keys}"
      end
    }
    status
  end

  def self.required_keys
    [:args, :rsbe_user, :rsbe_pass, :mongo_url, :sample_drupal_output, :drupal_config, :mongo_config]
  end

  def self.chk_required_values(options)
    status = true
    options.each { |k,v|
      unless v =~ /\w/ || v.is_a?(Hash)
        @error_msg << "#{k} cannot have a blank value"
        status = false
      end
    }
    status
  end


    def self.mongo_import(dir,hsh)
      ImportMongo.import(dir:dir, url: @mongo_url, photo_pg_hsh:hsh,config:@mongo_config)
    end

    def self.get_collection(coll_path)
      info = GetRsbeInfo.new(coll_path,@rsbe_user,@rsbe_pass)
      info.rsbe_hsh
    end

    def self.gen_hsh_config(config)
      hsh = {}
      File.foreach(config) do |line|
        line.chomp!
        unless line =~ /=/
          raise RuntimeError, "#{config} entry must have a delimiter of '='\n"
        end
        key,value = line.split("=")
        hsh[key] = value
      end
      hsh = hsh.map { |k, v| [k.to_sym, v] }.to_h
    end

    def self.process_import
      photo_hsh = PhotoPage.get_photo_hsh(dir:@args[:dir_name],path:@args[:path])
      if (@args[:import_type] == "drupal only") || (@args[:import_type] == "all")
        coll_info = get_collection(@args[:coll_path])
        coll_info[:dir_name] = @args[:dir_name]
        @drupal_config_hsh = gen_hsh_config(@drupal_config)
        json = gen_drupal_json(coll_info,photo_hsh)
        output_drupal_json(json,@args[:dir_name])
      end

      if (@args[:import_type] == "mongo only") || (@args[:import_type] == "all")
        mongo_import(@args[:dir_name],photo_hsh)
      end
    end

    def self.gen_drupal_json(coll_info, photo_hsh)
      drupal = GetDrupalJson.new(coll_info,photo_hsh,@drupal_config_hsh)
      drupal.sample_drupal_output = get_sample_json
      drupal.gen_drupal_json
      drupal
    end

    def self.output_drupal_json(json,filename)
      output_dir = json.output_dir
      unless Dir.exist?(output_dir)
        raise RuntimeError, "#{output_dir} must exist"
      end
      begin
        File.open("#{output_dir}/#{filename}.json","w+") do |f|
          f.write(JSON.generate(json.drupal_json_output))
        end
      rescue Exception => err
        raise RuntimeError, err
      end
    end

    def self.get_sample_json
      file_input = File.read(@sample_drupal_output)
      JSON.parse file_input.gsub('=>',':')
    end

  private_class_method :get_sample_json, :output_drupal_json, :gen_drupal_json, :process_import, :gen_hsh_config, :get_collection, :mongo_import, :chk_required_values, :set_instance_vars, :required_keys, :chk_options_keys, :validate_args
end
