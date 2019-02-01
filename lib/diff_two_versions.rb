###
# This program reads the JSON specification files and creates the Markdown files (minus the examples).
# Location: https://github.com/sumurthy/md_apispec
###
require 'json'

module SpecMaker

  # Initialize
  RESOURCES_NEW = "../jsonfiles/rest/"
  RESOURCES_OLD = "../jsonfiles/restold/"
  DIFF_OUT_FILE =  "../jsonfiles/diff2.json"
  NEWLINE = "\n"


  def self.camelcase (str="")
    if str.length > 0
      str[0, 1].downcase + str[1..-1]
    else
      str
    end
  end

  def self.do_diff(oldm=nil, newm=nil)
    oldh = JSON.parse(oldm, {:symbolize_names => true})
    newh = JSON.parse(newm, {:symbolize_names => true})

    oldp = []
    newp = []
    oldp_array = []
    newp_array = []

    if oldh[:properties].length > 0
      oldp = oldh[:properties].map{ |item| camelcase item[:name] }
      oldp_array = oldh[:properties].to_a
      oldp_array.each do |item|
        item.tap { |h| h.delete (:isNullable)}
      end
      #oldp_array = oldp_array.tap { |item| item.delete(:isNullable) }

    end


    if newh[:properties].length > 0
      newp = newh[:properties].map{ |item| camelcase item[:name] }
      newp_array = newh[:properties].to_a
      newp_array = newp_array.tap { |item| item.delete(:isNullable) }
      newp_array.each do |item|
        item.tap { |h| h.delete (:isNullable)}
      end
    end

    @diff[@key][:deletedproperties] = oldp - newp
    @diff[@key][:newproperties] = newp - oldp

    @diff[@key][:deletedproperties1] = oldp_array - newp_array
    @diff[@key][:newproperties1] = newp_array - oldp_array

    @diff[@key][:renames] = {}
    (newp - oldp).each do |name|
      @diff[@key][:renames][Random.rand(1..1000).to_s] = name
    end

    oldp = []
    newp = []

    if oldh[:methods].length > 0
      oldp = oldh[:methods].map{ |item| camelcase item[:name] }
    end

    if newh[:methods].length > 0
      #puts oldh[:properties].to_a.[0][:name]
      newp = newh[:methods].map{ |item| camelcase item[:name] }
    end

    # puts "old methods #{oldp}"
    # puts "new methods #{newp}"
    @diff[@key][:deletedmethods] = oldp - newp
    @diff[@key][:newmethods] = newp - oldp

  end

  #####
  # Main loop. Process each JSON files.
  #
  ###
  processed_files, imatch, iNew, iuntouched, imethods_changed = 0, 0, 0, 0, 0
  @diff = {}


  # For each of the new version, check against the existing version.

  Dir.foreach(RESOURCES_NEW) do |item|
    next if item == '.' or item == '..'

    next if item.include?('_collection')


    fullpath = RESOURCES_NEW + item.downcase

    #if File.file?(fullpath) && item == 'application.md'
    @key = item.chomp('.json')
    # next if @key != 'image'
    @diff[@key] = {}
    if File.file?(fullpath)
      processed_files = processed_files + 1
      #puts "-> #{item}"
      newm = File.read(fullpath, :encoding => 'UTF-8')
      fullpath2 = RESOURCES_OLD + item
      if File.file?(fullpath2)
        @diff[@key][:isNew] = false
        imatch = imatch + 1
        oldm = File.read(fullpath2, :encoding => 'UTF-8')
        do_diff(oldm, newm)
      else
        @diff[@key][:isNew] = true
        puts @key
        iNew = iNew + 1
      end

      if !@diff[@key][:isNew]
        if (@diff[@key][:deletedmethods].empty?) && (@diff[@key][:deletedproperties].empty?) && (@diff[@key][:newmethods].empty?) && (@diff[@key][:renames].empty?)
          @diff[@key][:untouched] = true
          iuntouched = iuntouched + 1
        else
          @diff[@key][:isUntouched] = false
        end
      else
        @diff[@key][:isUntouched] = nil
      end

      if !@diff[@key][:isNew]
        if !@diff[@key][:deletedmethods].empty? || !@diff[@key][:newmethods].empty?
          imethods_changed = imethods_changed + 1
          #puts "Removed methods: #{@diff[@key][:deletedmethods]}"
          #puts "Added methods: #{@diff[@key][:newmethods]}"
        end
      end
      if @diff[@key][:untouched]
        @diff.delete(@key)
      end

    end
  end


  File.open(DIFF_OUT_FILE, "w") do |f|
    f.write(JSON.pretty_generate @diff, :encoding => 'UTF-8')
  end
  ##

  puts ""
  puts "*** OK. Processed #{processed_files} input files."
  puts "*** Common resources #{imatch}"
  puts "*** Untouched #{iuntouched}"
  puts "*** Brand new #{iNew}"
  puts "*** Diff #{imatch - iuntouched}"
  puts "*** Methods changed #{imethods_changed}"

end