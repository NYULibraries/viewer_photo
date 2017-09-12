class PhotoPage
  def self.get_photo_hsh(dir:,path:)
    @dir = dir
    @path = path
    @full_path = "#{@path}/#{@dir}/aux"
    unless File.exist?(@full_path)
      raise RuntimeError, "#{@full_path} must exist\n"
    end
    jp2 = get_jp2
    get_pages(jp2)
  end

  def self.get_jp2
    files = Dir.glob("#{@full_path}/*jp2")
    if files.count == 0
     raise RuntimeError, "jp2 files mist exist here: #{@path}/#{@dir}/aux/\n"
    end
    files
  end

  def self.get_pages(files)
    photo_pages = []
    order = 1;
    files.each { |f|
      filename = File.basename(f)
      photo_pages << gen_page_hsh(filename,@dir,order)
      order += 1
    }
    photo_pages
  end

  def self.gen_page_hsh(filename,photo_id,order)
    uri = "fileserver://photo/#{photo_id}/#{filename}"
    { :isPartOf => photo_id,
      :sequence => [ order ],
      :realPageNumber => order,
      :cm => { :uri => uri,
               :width => "",
               :height => "",
               :levels => "",
               :dwtLevels => "",
               :compositingLayerCount => "",
               :timestamp => Time.now().to_i.to_s }
    }

  end
  private_class_method :gen_page_hsh, :get_pages, :get_jp2
end
