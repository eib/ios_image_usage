#!/usr/bin/ruby -w
#encoding: UTF-8
# https://github.com/eib/ios_image_usage
# MIT License: http://eib.mit-license.org/

root_dir = File.expand_path(Dir.pwd)

class Images
  attr_reader :all_images

  def initialize()
    @all_images = {}
  end
  
  def image_named(image_name)
    bundle_name = name_of_image_in_bundle image_name
    image = @all_images[bundle_name] || Image.new(bundle_name)
    @all_images[bundle_name] = image
    image
  end
end

class Image
  attr_accessor :bundle_name
  attr_accessor :image_files
  attr_accessor :references

  def initialize(bundle_name)
    @bundle_name = bundle_name
  	@image_files = []
  	@references = []
  end
  
  def image_name
    @image_files.first
  end
  
  def missing_image_files?
    @image_files.empty?
  end
  
  def missing_retina?
    @image_files.find { |filename| is_retina(filename) } == nil
  end
  
  def missing_non_retina?
    @image_files.find { |filename| !is_retina(filename) } == nil
  end
  
  def missing_references?
    @references.empty?
  end
  
  def duplicate_files?
    basenames = @image_files.map { |image| File.basename(image) }
    basenames.uniq.length != basenames.length
  end
end


# Listing files

def list_pngs(root_dir)
  list_files_with_extension root_dir, ".png"
end

def list_nibs(root_dir)
	list_files_with_extension root_dir, ".xib"
end

def list_code_files(root_dir)
	list_files_with_extension root_dir, ".m"
end

def list_plists(root_dir)
	list_files_with_extension root_dir, ".plist"
end

def list_files_with_extension(root_dir, ext)
  Dir.glob(File.join(root_dir, '**', "*#{ext}"));
end


# Content-scanning

def find_images_inside_nib(nib_name)
  File.read(nib_name).scan(/[^"]+[.]png/) || []
end

def find_images_inside_plist(plist)
  File.read(plist).scan(/[^>]+[.]png/) || []
end

def find_images_inside_code_file(file_name)
  File.read(file_name).force_encoding("ISO-8859-1").encode("utf-8", replace: nil).scan(/imageNamed:@"([^"]+)"/).flatten || []
end


# Images

def name_of_image_in_bundle(image_name)
	File.basename(image_name).sub(/(@2x)?[.]png$/, '')
end

def is_retina(filename)
	filename =~ /@2x/ ? true : false
end



if __FILE__ == $PROGRAM_NAME  
  images = Images.new

  list_pngs(root_dir).each do |image_name|
    image = images.image_named(image_name)
    image.image_files.push(image_name)
  end
  
  list_nibs(root_dir).each do |nib_name|
    find_images_inside_nib(nib_name).each do |image_name|
      image = images.image_named(image_name)
      image.references.push nib_name
    end
  end
  
  list_plists(root_dir).each do |plist|
    find_images_inside_plist(plist).each do |image_name|
      image = images.image_named(image_name)
      image.references.push plist
    end
  end
  
  list_code_files(root_dir).each do |filename|
    find_images_inside_code_file(filename).each do |image_name|
      image = images.image_named(image_name)
      image.references.push filename
    end
  end
  
  images.all_images.each do |bundle_name, image|
    if image.missing_image_files?
      puts "Missing image files: #{bundle_name} (references: #{image.references.join(', ')})"
    else
      if image.missing_retina?
        puts "Missing Retina version: #{image.image_name}"
      elsif image.missing_non_retina?
        puts "Missing non-Retina version: #{image.image_name}"
      end
    end
    
    if image.missing_references?
      puts "Missing References: #{image.image_name}"
    end
    
    if image.duplicate_files?
      puts "Duplicate files: #{image.image_files.join(', ')}"
    end
  end
end
