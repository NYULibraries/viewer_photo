class ProcessImportPhoto
  def self.run(options = {})
    @error_msg = []
    validate_args(options)
    if @error_msg.count > 0
      @error_msg.each { |m|
        LOG.error(m)
      }
      args_hsh = options[:args]
      dirname = args_hsh[:dir_name]
      LOG.info("Skipping processing #{dirname}")
    else
      set_instance_vars(options)
      process_import
      if @error_msg.count > 0
        @error_msg.each { |m|
          LOG.error(m)
        }
        LOG.error("Issues processing #{@args[:dir_name]}")
      elsif @error_msg.count == 0
        LOG.info("#{@args[:dir_name]} processed")
      end
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
    all_keys = required_keys + optional_keys
    unless options.keys.sort == all_keys.sort
      @error_msg << "#{required_keys.join(", ")} must be arguments."
      @error_msg << "Stack Trace:"
      caller.each { |c|
        @error_msg << c
      }
      status = false
    end

    options.keys.each { |o|
      unless all_keys.include?(o)
        status = false
        @error_msg << "#{options.keys} must match #{required_keys}"
        @error_msg << "Stack Trace:"
        caller.each { |c|
          @error_msg << c
        }
      end
    }
    status
  end

  def self.required_keys
    [:args, :rsbe_user, :rsbe_pass, :mongo_url, :sample_drupal_output, :drupal_config, :mongo_config]
  end
  
  def self.optional_keys
    [:handle]
  end

  def self.chk_required_values(options)
    status = true
    options.each { |k,v|
      unless v =~ /\w/ || v.is_a?(Hash)
        @error_msg << "#{k} cannot have a blank value"
        @error_msg << "Stack Trace:"
        caller.each { |c|
          @error_msg << c
        }
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
    begin
      File.foreach(config) do |line|
        line.chomp!
        unless line =~ /=/
          @error_msg << "#{config} entry must have a delimiter of '='\n"
          @error_msg << "Stack Trace:"
          caller.each { |c|
            @error_msg << c
          }
        end
        key,value = line.split("=")
        hsh[key] = value
      end
    rescue Exception => e
      @error_msg << e.to_s
      caller.each { |c|
        @error_msg << c
      }
    end
    hsh = hsh.map { |k, v| [k.to_sym, v] }.to_h
  end

  def self.process_import
    photo_hsh = PhotoPage.get_photo_hsh(dir:@args[:dir_name],path:@args[:path])
    unless photo_hsh.empty?
      if (@args[:import_type] == "drupal only") || (@args[:import_type] == "all")
        coll_info = get_collection(@args[:coll_path])
        unless coll_info.empty?
          coll_info[:dir_name] = @args[:dir_name]
          @drupal_config_hsh = gen_hsh_config(@drupal_config)
          unless @drupal_config_hsh.empty?
            json = gen_drupal_json(coll_info,photo_hsh)
            output_drupal_json(json,@args[:dir_name]) unless json.drupal_json_output.nil?
          end
        else
          @error_msg << "Problems finding collection/partner for #{@args[:dir_name]}"
        end
      end

      if (@args[:import_type] == "mongo only") || ((@args[:import_type] == "all") && @error_msg.size == 0)
        s = mongo_import(@args[:dir_name],photo_hsh)
        @error_msg << "ERROR processing mongo import for #{@args[:dir_name]}" unless s
      end

    else
      @error_msg << "photo hash cannot be empty"
    end
  end

  def self.gen_drupal_json(coll_info, photo_hsh)
    coll_hsh = coll_info.merge({:handle => @handle})
    drupal = GetDrupalJson.new(coll_hsh,photo_hsh,@drupal_config_hsh)
    drupal.sample_drupal_output = get_sample_json
    unless drupal.sample_drupal_output.nil?
      drupal.gen_drupal_json
    else
      @error_msg << "ERROR processing #{@sample_drupal_output}."
    end
    drupal
  end

  def self.output_drupal_json(json,filename)
    output_dir = json.output_dir
    unless Dir.exist?(output_dir)
      @error_msg << "#{output_dir} must exist"
      caller.each { |c|
        @error_msg << c
      }
    end
    begin
      File.open("#{output_dir}/#{filename}.json","w+") do |f|
        f.write(JSON.generate(json.drupal_json_output))
      end
    rescue Exception => err
      @error_msg << err
    end
  end

  def self.get_sample_json
    json = nil
    begin
      file_input = File.read(@sample_drupal_output)
    rescue Exception => e
      @error_msg << e.to_s
      caller.each { |c|
        @error_msg << c
      }
    end
    json = JSON.parse file_input.gsub('=>',':') if file_input
  end

  private_class_method :get_sample_json, :output_drupal_json, :gen_drupal_json, :process_import, :gen_hsh_config, :get_collection, :mongo_import, :chk_required_values, :set_instance_vars, :required_keys, :chk_options_keys, :validate_args, :optional_keys
end
