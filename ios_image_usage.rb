#!/usr/bin/ruby -w
#encoding: UTF-8
# https://github.com/eib/ios_image_usage
# MIT License: http://eib.mit-license.org/


class Image
  attr_reader :bundle_name
  attr_reader :image_files
  attr_reader :references

  def initialize(bundle_name)
    @bundle_name = bundle_name
  	@image_files = []
  	@references = []
  end
  
  def image_name
    @image_files.first
  end
  
  def add_file(image_name)
    @image_files.push(image_name)
  end
  
  def add_reference(filename)
    @references.push(filename)
  end
  
  def missing_image_files?
    @image_files.empty?
  end
  
  def missing_retina?
    !missing_image_files? && @image_files.find { |filename| is_retina(filename) } == nil
  end
  
  def missing_non_retina?
    !missing_image_files? && @image_files.find { |filename| !is_retina(filename) } == nil
  end
  
  def missing_iphone_versions?
    !missing_image_files? && @image_files.find { |filename| !is_ipad_specific(filename) } == nil
  end
  
  def missing_ipad_versions?
    !missing_image_files? && @image_files.find { |filename| !is_iphone_specific(filename) } == nil
  end
  
  def missing_references?
    @references.empty?
  end
  
  def duplicate_files?
    basenames = @image_files.map { |image| File.basename(image) }
    basenames.uniq.length != basenames.length
  end
  
  def self.name_of_image_in_bundle(image_name)
    File.basename(image_name).sub(/(@2x)?([~][a-z]+)?[.]png$/i, '')
  end

  def is_retina(filename)
    filename =~ /@2x/ ? true : false
  end
  
  def is_ipad_specific(filename)
    filename =~ /~ipad([.]png)?$/i ? true : false
  end
  
  def is_iphone_specific(filename)
    filename =~ /~iphone([.]png)?$/i ? true : false
  end
end


class Images
  attr_reader :all_images
  attr_reader :root_dir

  def initialize(root_dir = '.')
    @root_dir = File.expand_path(root_dir)
    @all_images = {}
  end
  
  def image_named(image_name)
    bundle_name = Image.name_of_image_in_bundle(image_name)
    @all_images[bundle_name] = (@all_images[bundle_name] || Image.new(bundle_name))
  end
  
  def print_usage
    find_image_files { |image_name| image_named(image_name).add_file(image_name) }
    find_image_references { |reference, image_name| image_named(image_name).add_reference(reference) }
  
    @all_images.each do |bundle_name, image|
      image.missing_iphone_versions?
      image.missing_ipad_versions?
      #next
      #puts "Image: [#{bundle_name}] #{image.image_name}: #{image.references.join(', ')}"; next
      
      if image.missing_image_files?
        puts "Missing image files: #{bundle_name} (references: #{image.references.join(', ')})"
      elsif image.missing_references?
        puts "Missing references: #{image.image_name}"
      end

      if image.missing_retina?
        puts "Missing Retina version: #{image.image_name}"
      elsif image.missing_non_retina?
        puts "Missing non-Retina version: #{image.image_name}"
      end
        
      if image.missing_iphone_versions?
        puts "Missing iPhone version: #{image.image_name}"
      elsif image.missing_ipad_versions?
        puts "Missing iPad version: #{image.image_name}"
      end
    
      if image.duplicate_files?
        puts "Potentially duplicate files: #{image.image_files.join(', ')}"
      end
    end
  end
  
  # Searches

  def find_image_files(&blk)
    list_files_with_extension(".png").each do |file|
      blk.call(file)
    end
  end
  
  def find_image_references
    patterns_by_extension = Hash.new
    patterns_by_extension['.m'] = /imageNamed:@"([^"]+)"/
    patterns_by_extension['.xib'] = /[^"]+[.]png/i
    patterns_by_extension['.plist'] = /[^>]+[.]png/i
    
    patterns_by_extension.each do |extension, pattern|
      list_files_with_extension(extension).each do |filename|
        scan_file_for_matches(filename, pattern).each do |image_name|
          yield [filename, image_name]
        end
      end
    end
  end

  def list_files_with_extension(ext)
    Dir.glob(File.join(@root_dir, '**', "*#{ext}"));
  end
  
  def scan_file_for_matches(filename, pattern)
    File.read(filename).force_encoding("ISO-8859-1").encode("utf-8", replace: nil).scan(pattern).flatten || []
  end
end

if __FILE__ == $PROGRAM_NAME
  images = Images.new
  images.print_usage
end
