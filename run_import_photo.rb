require 'rubygems'
require 'optparse'
require 'pry'
require 'logger'
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
def chk_dir_existence(path,dir)
  status = false
  se = "#{path}/#{dir}"
  if Dir.exist?(se)
    status = true
  end
  status
end

def chk_file_existence(path)
  status = false
  status = true if File.exist?(path)
end

def chk_handle(path,dir)
  status = false
  handle_file = "#{path}/#{dir}/handle"
  status = true if chk_file_existence(handle_file)
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
    if args[:import_type] == "drupal only" or args[:import_type] == "all"
      chk_file = chk_handle(args[:path],args[:dir_name])
      errors << "Handle file: #{args[:path]}/#{args[:dir_name]}/handle must exist" unless chk_file
    end  
  end
  chk_dir = chk_dir_existence(args[:path],args[:dir_name])
  errors << "#{args[:path]}/#{args[:dir_name]} must exist" unless chk_dir
  
  print_usage_err_exit(errors.join("\n")) unless errors.empty?
end

def create_import_photo_hsh(args)
  hsh = { :args => args,
    :mongo_config => @mongo_config,
    :mongo_url => ENV['MONGO_URL'],
    :rsbe_user => ENV['RSBE_USER'],
    :rsbe_pass => ENV['RSBE_PASS'],
    :sample_drupal_output => @sample_drupal_output,
    :drupal_config => @drupal_config
  }
  unless args[:import_type] == "mongo only"
    hsh = hsh.merge ({ :handle => "#{args[:path]}/#{args[:dir_name]}/handle" })
  end
  hsh
end

@mongo_only = ["mongo only"]
@others = ["drupal only", "all"]
args = parse_args
validate_args(args)
@mongo_config = "#{Dir.pwd}/config/.mongo"
@drupal_config = "#{Dir.pwd}/config/.drupal"
@sample_drupal_output = "#{Dir.pwd}/config/sample_drupal_json_output_hsh"
LOG = Logger.new("logs/import_#{Time.now.to_i}.txt")
LOG.info("Starting: #{args[:dir_name]}")
run_hsh = create_import_photo_hsh(args)
ProcessImportPhoto.run(run_hsh)
