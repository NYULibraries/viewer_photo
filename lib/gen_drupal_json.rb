class GetDrupalJson
  attr_reader :drupal_json

  def initialize(coll_info,photo_hsh,config)
    @coll_info = coll_info
    @photo_hsh = photo_hsh
    @config = config
    @drupal_hsh = {}
    @drupal_json = gen_drupal_json
  end

  def gen_drupal_json
    create_header
    gen_metadata
  end

  private
  def create_header
    @drupal_hsh[:entity_title] = @coll_info[:dir_name]
    @drupal_hsh[:identifier] = @coll_info[:dir_name]
    @drupal_hsh[:entity_language] = @config[:entity_language]
    @drupal_hsh[:entity_status] = @config[:entity_status]
    @drupal_hsh[:entity_type] = @config[:entity_type]
    @drupal_hsh
  end

  def gen_metadata
    title_info = gen_title
    @drupal_hsh[:metadata] = title_info
    @drupal_hsh
  end

  def gen_title
    title_hsh = {}
    title_info_hsh = {}
    title_info_hsh[:label] = "Title"
    title_info_hsh[:value] = [@coll_info[:dir_name]]
    title_info_hsh[:field_type] = "text_textfield"
    title_info_hsh[:machine_name] = "field_title"
    title_hsh[:title] = title_info_hsh
    title_hsh
  end
end
