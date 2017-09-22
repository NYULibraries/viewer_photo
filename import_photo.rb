require 'rubygems'
require 'open3'

def validate_args
  chk_arg_count

  ARGV.each_index { |i|
    case i
    when 0
     raise ArgumentError, "#{ARGV[i]} must exist" unless File.exist?(ARGV[i])
    when 1
     raise ArgumentError, "#{ARGV[i]} must exist" unless Dir.exist?(ARGV[i])
    when 2
     raise ArgumentError, "#{ARGV[i]} must be one of these #{import_types.join(',')}" unless import_types.include?(ARGV[i])
     raise ArgumentError, "Collection url file path must not be blank" if (ARGV[3].nil? && ARGV[2] != "mongo only")
    when 3
     raise ArgumentError, "#{ARGV[i]} must be a file" unless File.exist?(ARGV[i])
    end 
  }   
     
end

def import_types
  ["drupal only", "mongo only", "all"]
end

def chk_arg_count
  raise ArgumentError, "Arg count should equal 3 or 4" unless ARGV.count == 3 || ARGV.count == 4
end

file=ARGV[0]
wip_path=ARGV[1]
import_type=ARGV[2]
coll_url_file=ARGV[3]

validate_args
coll_url_cmd = import_type != "mongo only" ? " -c #{coll_url_file}" : nil
File.foreach(file) do |d|
  d.chomp!
  p "Processing #{d}"
  cmd = "ruby run_import_photo.rb -p #{wip_path} -d #{d} -i \"#{import_type}\"#{coll_url_cmd}"
  out,e,s = Open3.capture3(cmd)
  if e != ""
   p e
   p "Problems running script. Please check log"
  else 
  p out
  end
end
