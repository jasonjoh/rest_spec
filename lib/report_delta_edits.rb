###
# This program reads the JSON specification files and creates the Markdown files (minus the examples).
# Location: https://github.com/sumurthy/md_apispec
###
require 'pathname'
require 'logger'
require 'json'

module SpecMaker

  # Initialize
  DIFF_JSON = "../jsonFiles/diff2.json"
  NEWLINE = "\n"
  COMMON_FILE = "../jsonFiles/common.csv"
  NEW_FILE = "../jsonFiles/new.csv"

  @diffHash = JSON.parse(File.read(DIFF_JSON, :encoding => 'UTF-8'), {:symbolize_names => true})
  resources, iNew, imatch,iuntouched, inewmembers, iremovemembers, inewapi, iremovapi = 0, 0, 0, 0, 0, 0, 0, 0
  @csv_common = []
  @csv_new = []

  def self.append_to_member(resource=nil, action=nil, item={})
    @csv_common.push "#{resource}, #{action} Member, #{item[:name]}, #{item[:isRelationship]}, #{item[:dataType].to_s}, #{item[:enumName].to_s}, #{item[:isReadOnly]} \n"
  end

  def self.append_to_api(resource=nil, action=nil, member)
    @csv_common.push "#{resource}, #{action} API, #{member} \n"
  end

  def self.add_to_new_resource(resource=nil)
    @csv_new.push "#{resource} \n"
  end

  #####
  # Main loop. Process each JSON files.
  #
  ###
  @diffHash.each do |key, val|

     puts "#{key}"
     puts "#{val}"
    resources = resources + 1
    if val[:isNew]
      add_to_new_resource(key.to_s)
      iNew = iNew + 1
    else
      imatch = imatch + 1
      if val[:isUntouched]
        iuntouched = iuntouched + 1
        next
      end
      if val[:deletedproperties1].length > 0
        val[:deletedproperties1].each do |item|
          append_to_member(key.to_s, "Remove", item)
          iremovemembers = iremovemembers + 1
        end
      end

      if val[:newproperties1].length > 0
        val[:newproperties1].each do |item|
          append_to_member(key.to_s, "Add", item)
          inewmembers = inewmembers + 1
        end
      end

      if val[:newmethods].length > 0
        val[:newmethods].each do |item|
          append_to_api(key.to_s, "Add", item)
          inewapi = inewapi + 1
        end
      end

      if val[:deletedmethods].length > 0
        val[:deletedmethods].each do |item|
          append_to_api(key.to_s, "Remove", item)
          iremovapi = iremovapi + 1
        end
      end
    end
  end

  file=File.new(COMMON_FILE,'w')
  @csv_common.each do |line|
    file.write line
  end

  file=File.new(NEW_FILE,'w')
  @csv_new.each do |line|
    file.write line
  end

  ##

  puts ""
  puts "*** OK. Processed #{resources} input files."
  puts "*** Common resources #{imatch}"
  puts "*** Untouched #{iuntouched}"
  puts "*** Brand new #{iNew}"
  puts "*** New members #{inewmembers}"
  puts "*** Removed members #{iremovemembers}"
  puts "*** New API #{inewapi}"
  puts "*** Removed API #{iremovapi}"


end