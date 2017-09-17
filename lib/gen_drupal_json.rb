class GetDrupalJson
  attr_accessor :sample_drupal_output
  attr_reader :drupal_json_output, :output_dir

  def initialize(coll_info,photo_hsh,config)
    @coll_info = coll_info
    @photo_hsh = photo_hsh
    @config = config
  end

  def gen_drupal_json
    @drupal_hsh = sample_drupal_output
    create_header
    gen_metadata
    @drupal_json_output = @drupal_hsh
    @output_dir = @config[:output_dir]
  end

  private
  def create_header
     @drupal_hsh["entity_title"] = @coll_info[:dir_name]
     @drupal_hsh["identifier"] = @coll_info[:dir_name]
     @drupal_hsh["entity_language"] = @config[:entity_language]
     @drupal_hsh["entity_status"] = @config[:entity_status]
     @drupal_hsh["entity_type"] = @config[:entity_type]
    @drupal_hsh
  end

  def gen_metadata
    @metadata = @drupal_hsh["metadata"]
    gen_title
    gen_coll
    gen_partner_info
    get_handle
    get_page_info
    add_pages
  end

  def gen_title
    @metadata["title"]["value"] << @coll_info[:dir_name]
  end

  def gen_coll
    coll_md = @metadata["collection"]["value"]
    coll_md["title"] = @coll_info[:coll_name]
    coll_md["identifier"] = @coll_info[:coll_identifier]
    coll_md["code"] = @coll_info[:coll_code]
    coll_md["name"] = @coll_info[:coll_name]
  end

  def gen_partner_info
    coll_partner_info
    partner_hsh_info
  end

  def coll_partner_info
    coll_partner = @metadata["collection"]["value"]["partner"]
    coll_partner["title"] = @coll_info[:partner_name]
    coll_partner["code"] = @coll_info[:partner_code]
    coll_partner["identifier"] = @coll_info[:partner_id]
    coll_partner["name"] = @coll_info[:partner_name]
  end

  def partner_hsh_info
    partner_info = @metadata["partner"]["value"]
    partner_info["title"] = @coll_info[:partner_name]
    partner_info["code"] = @coll_info[:partner_code]
    partner_info["name"] = @coll_info[:partner_name]
    partner_info["identifier"] = @coll_info[:partner_id]
  end

  def get_handle
    @metadata["handle"]["value"] << "Add some handle reading code here"
  end

  def get_page_info
    pg_only
    sequence_only
  end

  def pg_only
    @metadata["page_count"]["value"] << @photo_hsh.size
  end

  def sequence_only
    @metadata["sequence_count"]["value"] << @photo_hsh.size
  end

  def add_pages
    @drupal_hsh["pages"]["page"] = @photo_hsh
  end
end
