require 'rubygems'
require 'open3'
require 'pry'

def validate_args
  chk_arg_count
  check_each_arg
  required_files = chk_dir
  required_files
end

def chk_dir
  path = ARGV[0]
  req = {}
  empty_files = []
  path = path =~ /.*\/$/ ? path + "*" : path + "/*"  
  files = Dir.glob(path)
  filenames_only = files.collect { |f| File.basename(f) }
  files.each { |f|
    empty_files << f if File.file?(f) and File.zero?(f)
  }
  raise ArgumentError, "#{empty_files.join(", ")} cannot be empty" if empty_files.count != 0
  req_files.each { |r|
    if filenames_only.include?(r)
     f = files.select { |x| x.match(/.*?#{r}$/) }
     req[r] = f[0] if f.size == 1
    end
  } 
  raise ArgumentError, "Required files are #{req_files.join(",")}" if req.keys.size != req_files.count
  req 
end

def check_each_arg
  ARGV.each_index { |i|
    case i
    when 0
     raise ArgumentError, "#{ARGV[i]} must exist" unless Dir.exist?(ARGV[i])
    when 1
     raise ArgumentError, "#{ARGV[i]} must be one of these #{import_types.join(',')}" unless import_types.include?(ARGV[i])
    end 
  }   
     
end

def req_files
  ["wip_path","collection_url","se_list"]
end

def import_types
  ["drupal only", "mongo only", "all"]
end

def chk_arg_count
  if ARGV.count != 2
    usage
    raise ArgumentError, "Arg count should equal 2"
  end
end

def get_info(file)
  File.read(file).chomp!
end

def chk_se_list
  se_list = @required_files["se_list"]
  lc,e,s = Open3.capture3("wc -l #{se_list}")
  if s == 0
    lc = lc.split(" ")[0].to_i
  else
    raise ArgumentError, "Can't run command to get line count: #{e}"
  end
  lc 
end

def get_se_list(lc)
  ses = @required_files["se_list"]
  dir = @required_files["dir"] 
  new_se_list = nil
  se_basename = File.basename(ses)
  o,e,s = Open3.capture3("split -l #{MAX_LINES} #{ses} #{dir}/split-#{se_basename}-")
  if s == 0
    new_se_list = Dir.glob("#{dir}/split-#{se_basename}-*")
  else
    raise ArgumentError, "Can't run command to split SE file: #{e}"
  end 
  new_se_list
end

def usage
  puts "============USAGE==========="
  puts
  puts
  puts "SCRIPT CALL PATTERN:  #{$0} path/to/dir import type"
  puts "EXAMPLE CALL PATTERN: #{$0} ~/dir all"
  puts
  puts
  puts "acceptable import types are \"mongo only\", \"drupal only\", \"all\""
  puts "directory should contain the following files with the following file names:"
  puts "          wip_path, a one liner which contains the path of the wip"
  puts "          collection_url, a one liner which contains the path to the collection url file"
  puts "          se_list, a list of SEs"
  puts
  puts
  puts "============USAGE==========="
end

# command that runs the actual import to mongo and generates json files for drupal
def run_import(se_list)
  coll_url_cmd = @import_type != "mongo only" ? " -c #{@collection_url}" : nil
  cmd = "ruby run_import_photo.rb -p #{@wip_path} -f #{se_list} -i \"#{@import_type}\"#{coll_url_cmd}"
  p cmd
  out,e,s = Open3.capture3(cmd)
  if e != ""
   p e
   p "Problems running script. Please check log"
  else 
   p out
  end

end


dir=ARGV[0]
@import_type=ARGV[1]
# mongodb threads give out if se list has more than 300 SEs,
# so, I have this hack-ish workaround 
# I split the SE list by 300
# and run the command per 300 SEs.
MAX_LINES = 300
@required_files = validate_args
@required_files["dir"] = dir
@collection_url = get_info(@required_files["collection_url"])
@wip_path = get_info(@required_files["wip_path"])

# gets line count of SEs
lc = chk_se_list

# if line count is greater than 300, split up the files
# get_se_list returns an array of split up SE files
# if less than 300, se_list is a string - a path to the SE file
@se_list = lc > MAX_LINES ? get_se_list(lc) : @required_files["se_list"]
if @se_list.is_a?(Array)
  @se_list.each { |se|
   run_import(se)
  }
else
  run_import(@se_list)
end

