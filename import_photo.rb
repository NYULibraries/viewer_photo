require 'rubygems'
require 'optparse'
require 'pry'
Dir["./lib/*.rb"].each {|file| require file }

def err_exit
  exit 1
end

def print_err(msg)
  $stderr.puts "#{msg}"
end

def print_err_exit(msg = '')
  print_err(msg)
  err_exit
end

def print_usage
  print_err usage
end

def print_usage_err_exit(msg = '')
  print_err(msg)
  print_usage
  err_exit
end

def usage
  <<USAGE

Please set the following environment vars:
   MONGO_URL - with the url of the mongo database if importing to mongodb
   RSBE_USER - with the username for RSBE if generating JSON for Drupal
   RSBE_PASS - with the password for RSBE if generating JSON for Drupal

usage: #{$PROGRAM_NAME} -p /path/to/wips -d dir -c /path/to/coll/url -i "drupal only"
  e.g. #{$PROGRAM_NAME} -p /content/prod/wip -d MSS204 -c /content/prod/partner/coll/coll_url -i "all"

  valid import types are one of these: #{usage_import_types}

USAGE
end

def usage_import_types
  usage = import_types.join(", ")
end

def import_types
  @others + @mongo_only
end

def parse_args
  args = {}
  OptionParser.new do |opts|
    opts.banner = usage
    opts.on('-p', '--path PATH', '(required)') { |x| args[:path] = x }
    opts.on('-c', '--coll-path PATH TO FILE CONTAINING COLL URL', '(required for two import types)') { |x| args[:coll_path] = x }
    opts.on('-d', '--dir_name DIR', '(required)') { |x| args[:dir_name] = x }
    opts.on('-i', '--import_type DRUPAL', '(required)') { |x| args[:import_type] = x.downcase }
  end.parse!
  args
end

def validate_import_type(import_type)
  import_types.include?(import_type)
end

def check_env_var(import_type)
  status = true
  case import_type
  when "mongo only"
    if ENV['MONGO_URL'].nil?
      status = false
    end
  else
    if ENV['RSBE_USER'].nil? || ENV['RSBE_PASS'].nil?
      status =false
    end
  end
  status
end

def chk_import_type(type,errors)
  errors << "ERROR: import type must be one of these: #{usage_import_types}" unless validate_import_type(type)

  errors << "ERROR: env var: MONGO_URL, RSBE_USER, RSBE_PASS must be set" unless check_env_var(type)

  errors
end

def validate_args(args)
  errors = []
  errors << 'ERROR: missing argument: path' if args[:path].nil?
  if args[:coll_path].nil? and @others.include?(args[:import_type])
    errors << 'ERROR: missing argument: collection path' if args[:coll_path].nil?
  end
  errors << 'ERROR: missing argument: dir_name' if args[:dir_name].nil?
  errors << 'ERROR: missing argument: import_type' if args[:import_type].nil?
  if args[:import_type]
    chk_import_type(args[:import_type],errors)
  end
  print_usage_err_exit(errors.join("\n")) unless errors.empty?
end

def mongo_import(dir,hsh)
  ImportMongo.import(dir:dir, url: ENV['MONGO_URL'], photo_pg_hsh:hsh,config:@mongo_config)
end

def get_collection(coll_path)
  info = GetRsbeInfo.new(coll_path,ENV['RSBE_USER'],ENV['RSBE_PASS'])
  info.rsbe_hsh
end

def gen_hsh_config(config)
  hsh = {}
  File.foreach(config) do |line|
    line.chomp!
    unless line =~ /=/
     raise RuntimeError, "#{@config} entry must have a delimiter of '='\n"
    end
    key,value = line.split("=")
    hsh[key] = value
  end
  hsh = hsh.map { |k, v| [k.to_sym, v] }.to_h
end

def process_import(args)
  photo_hsh = PhotoPage.get_photo_hsh(dir:args[:dir_name],path:args[:path])
  if (args[:import_type] == "drupal only") || (args[:import_type] == "all")
    coll_info = get_collection(args[:coll_path])
    coll_info[:dir_name] = args[:dir_name]
    @drupal_config_hsh = gen_hsh_config(@drupal_config)
    gen_drupal_json(coll_info,photo_hsh)
  end

  if (args[:import_type] == "mongo only") || (args[:import_type] == "all")
    mongo_import(args[:dir_name],photo_hsh)
  end
end

def gen_drupal_json(coll_info, photo_hsh)
  d = GetDrupalJson.new(coll_info,photo_hsh,@drupal_config_hsh)
  binding.pry
end


@mongo_only = ["mongo only"]
@others = ["drupal only", "all"]
args = parse_args
validate_args(args)
@mongo_config = "config/.mongo"
@drupal_config = "config/.drupal"
process_import(args)
