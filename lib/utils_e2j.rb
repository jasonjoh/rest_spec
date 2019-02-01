require 'active_support'
require 'active_support/core_ext'
require 'json'
require 'logger'
# require 'FileUtils'

module SpecMaker
  JSON_BASE_FOLDER = "../jsonFiles/#{$options[:version]}/"
  JSON_SOURCE_FOLDER = JSON_BASE_FOLDER + 'rest/'
  JSON_SETTINGS_FOLDER = JSON_BASE_FOLDER + 'settings/'
  JSON_PREV_SOURCE_FOLDER = JSON_BASE_FOLDER + 'rest_previous/'
  ENUMS = JSON_SETTINGS_FOLDER + 'restenums.json'
  ACTIONS = JSON_BASE_FOLDER + 'actions.json'
  ANNOTATIONS = JSON_SETTINGS_FOLDER + 'annotations.json'
  CSDL_LOCATION = "../data/#{$options[:version]}/"

  JSON_EXAMPLE_FOLDER = JSON_BASE_FOLDER + 'examples/'
  BASETYPES = %w[Entity directoryObject Attachment Message OutlookItem Extension]
  BASETYPES_ALLCASE = BASETYPES.concat BASETYPES.map(&:downcase)

  ####
  # This is to address the special entityType:
  # <EntityType Name="Extension" BaseType="Microsoft.Graph.Entity" />
  # Here, there is no property or nav.prop defined for Extension. It simply
  # points back to the Entity. If more such cases arise, add an entry here.
  #
  ##
  BASETYPE_MAPPING = {
    "Extension" => "extension",
    "extension" => "extension"
  }
  # Load the template
  # JSON_TEMPLATE = "../jsonFiles/template/restresourcetemplate.json"
  # @template = JSON.parse(File.read(JSON_TEMPLATE, :encoding => 'UTF-8'), {:symbolize_names => true})

  # Load the structure
  JSON_STRUCTURE = "../jsonFiles/template/restresource_structures.json"
  @struct = JSON.parse(File.read(JSON_STRUCTURE, :encoding => 'UTF-8'), {:symbolize_names => true})
  @template = @struct[:object]
  @service = @struct[:serviceSettings]

  Dir.mkdir(JSON_BASE_FOLDER) unless File.exist?(JSON_BASE_FOLDER)
  Dir.mkdir(CSDL_LOCATION) unless File.exist?(CSDL_LOCATION)

  Dir.mkdir(JSON_SOURCE_FOLDER) unless File.exist?(JSON_SOURCE_FOLDER)
  FileUtils.rm Dir.glob(JSON_SOURCE_FOLDER + '/*')
  Dir.mkdir(JSON_SETTINGS_FOLDER) unless File.exist?(JSON_SETTINGS_FOLDER)

  # Log file
  LOG_FOLDER = '../logs'
  Dir.mkdir(LOG_FOLDER) unless File.exist?(LOG_FOLDER)

  LOG_FILE = File.basename($PROGRAM_NAME, ".rb") + ".txt";
  if File.exist?("#{LOG_FOLDER}/#{LOG_FILE}")
    File.delete("#{LOG_FOLDER}/#{LOG_FILE}")
  end
  @logger = Logger.new("#{LOG_FOLDER}/#{LOG_FILE}")
  @logger.level = Logger::DEBUG
  # End log file

  @iprop = 0
  @ienums = 0
  @inprop = 0
  @ient = 0
  @ictypes = 0
  @imethod = 0
  @iparam = 0
  @iaction = 0
  @ifunction = 0
  @ientityset = 0
  @icollection = 0
  @ibasetypemerges = 0
  @iann = 0
  @isingleton = 0

  @methods = {}
  @enum_objects = {}
  @json_object = nil
  @base_types = {}
  @iexampleFilesWrittem = 0
  @annotations = {}

  def self.camelcase(str = "")
    if str.length > 0
      str
      # str[0, 1].downcase + str[1..-1]
    else
      str
    end
  end

  def self.parse_annotations(target, annotations)
    if annotations
      if annotations.is_a?(Array)
        annotations.each do |annotation|
          parse_annotation(target, nil, annotation)
        end
      else
        parse_annotation(target, nil, annotations)
      end
    end
  end

  def self.parse_annotation(target, term, annotation)
    # puts "-> Processing Annotation; Target: #{target}; Term: #{term}; Annotation: #{annotation}"

    if annotation[:Term]
      term = get_type(annotation[:Term]).downcase
    elsif annotation[:Property]
      term = term + "/" + annotation[:Property].downcase
    end

    if !@annotations[target]
      @annotations[target] = {}
    end

    if annotation[:Bool]
      if annotation[:Bool].downcase == 'true'
        @annotations[target][term] = true
      else
        @annotations[target][term] = false
      end
    elsif annotation[:String]
      @annotations[target][term] = annotation[:String]
    elsif annotation[:Record]
      if annotation[:Record][:PropertyValue]
        if annotation[:Record][:PropertyValue].is_a?(Array)
          annotation[:Record][:PropertyValue].each do |propertyValue|
            parse_annotation(target, term, propertyValue)
          end
        else
          parse_annotation(target, term, annotation[:Record][:PropertyValue])
        end
      end
    elsif annotation[:Collection]
      # TODO
    end
  end

  def self.set_description(target, itemToSet)
    target = target.downcase
    # puts "-> Getting Annotation; Target: #{target}"
    if @annotations[target]
      if @annotations[target]["description"]
        itemToSet[:description] = @annotations[target]["description"]
      end
    end
  end

  ###
  # Create object_method-name.md file in lowercase.
  #
  #
  def self.create_examplefile(objectName = nil, methodName = nil)
    File.open(JSON_EXAMPLE_FOLDER + (objectName + '_' + methodName).downcase + ".md", "w") do |f|
      f.write('##### Example', :encoding => 'UTF-8')
      @iexampleFilesWrittem = @iexampleFilesWrittem + 1
    end
  end

  ###
  # Create example files for object/collection.
  #
  #
  def self.create_auto_examplefiles(objectName = nil, isCollection)
    if !isCollection
      create_examplefile(objectName, 'auto_get')
      create_examplefile(objectName, 'auto_post')
      create_examplefile(objectName, 'auto_patch')
      create_examplefile(objectName, 'auto_put')
      create_examplefile(objectName, 'auto_delete')
    else
      create_examplefile(objectName, 'auto_list')
    end
  end

  ###
  # Create example files from array that contains many methods (1 per method)
  #
  #
  def self.create_basetype_examplefiles(methods = [], objectName = nil)
    methods.each do |item|
      create_examplefile(objectName, item[:name])
    end
  end

  ###
  # To prevent shallow copy errors, need to get a new object each time.
  #
  #
  def self.deep_copy(o)
    Marshal.load(Marshal.dump(o))
  end

  ###
  # Copy method description, display name, parameter descriptions, etc.
  #	from an existing JSON file from previous run.
  #
  #
  def self.preserve_method_descriptions(objectName = nil, method = nil)
    fullpath = JSON_PREV_SOURCE_FOLDER + objectName.downcase + '.json'
    if File.file?(fullpath)
      prevObject = JSON.parse(File.read(fullpath, :encoding => 'UTF-8'), {:symbolize_names => true})
      prevMethods = prevObject[:methods]
      prevMethods.each do |item|
        if item[:name] == method[:name]
          method[:description] = item[:description] if !item[:description].empty?
          method[:displayName] = item[:displayName] if item[:displayName] && !item[:displayName].empty?
          method[:prerequisites] = item[:prerequisites] if !item[:prerequisites].empty?
          method[:parameters].each do |param|
            item[:parameters].each do |paramOld|
              if paramOld[:name] == param[:name]
                param[:description] = paramOld[:description] if !paramOld[:description].empty?
              end
            end
          end
        end
      end
    end
    return method
  end

  def self.preserve_object_property_descriptions(objectName = nil)
    fullpath = JSON_PREV_SOURCE_FOLDER + objectName.downcase + '.json'
    if File.file?(fullpath)
      prevObject = JSON.parse(File.read(fullpath, :encoding => 'UTF-8'), {:symbolize_names => true})
      @json_object[:description] = prevObject[:description]
      prevProperties = prevObject[:properties]
      prevProperties.each do |item|
        @json_object[:properties].each do |currentProp|
          if item[:name] == currentProp[:name]
            currentProp[:description] = item[:description]
          end
        end
      end
      # else
      # 	puts "-----> No previous JSON file version exists for this resource."
    end
  end

  ###
  # Extract only the type name. Example: Collection(Microsoft.Graph.Recipient) to Recipient
  # and Microsoft.Graph.Recipient to Recipient
  #
  def self.get_type(t = nil)
    return camelcase t[(t.rindex('.') + 1)..-1].chomp(')')
  end

  def self.merge_members(current = nil, base = nil)
    # if objectName != nil
    # 	if base.is_a?(Hash)
    # 		dt = get_type(base[:Type])
    # 		return current if dt.downcase == objectName.downcase
    # 	elsif base.is_a?(Array)
    # 		base.each_with_index do |item, i|
    # 			dt = get_type(item[:Type])
    # 				base.delete_at(i) if dt == objectName
    # 		end
    # 	end
    # end

    arr = []
    if current.nil?
      return base
    elsif current.is_a?(Array)
      if base.nil?
        return current
      elsif base.is_a?(Array)
        return current.concat base
      elsif base.is_a?(Hash)
        return current.push base
      end
    elsif current.is_a?(Hash)
      if base.nil?
        return current
      elsif base.is_a?(Array)
        arr = base
        return arr.push current
      elsif base.is_a?(Hash)
        arr.push base
        arr.push current
        return arr
      end
    end
  end

  def self.process_property(className, item = nil)
    prop = deep_copy(@struct[:property])
    prop[:name] = camelcase item[:Name]
    dt = get_type(item[:Type])
    prop[:isCollection] = true if item[:Type].start_with?('Collection(')
    prop[:dataType] = dt
    if @enum_objects.has_key?(dt.to_sym)
      prop[:enumName] = dt
      prop[:dataType] = "string"
    end
    if @key_save.include?(item[:Name])
      prop[:isKey], prop[:isReadOnly] = true, true
    end
    if item[:Nullable] == 'false'
      prop[:isNullable] = false
    end
    if item[:Unicode] == 'false'
      prop[:isUnicode] = false
    end
    @iprop = @iprop + 1

    annotationTarget = className + "/" + item[:Name]
    parse_annotations(annotationTarget, item[:Annotation])
    set_description(annotationTarget, prop)

    return prop
  end

  def self.process_navigation(className, item = nil)
    prop = deep_copy(@struct[:property])
    prop[:name] = camelcase item[:Name]
    prop[:isRelationship] = true
    dt = get_type(item[:Type])
    prop[:isCollection] = true if item[:Type].start_with?('Collection(')
    prop[:dataType] = dt
    prop[:isNullable] = true
    prop[:isReadOnly] = true
    if item[:Nullable] == 'false'
      prop[:isNullable] = false
    end
    if item[:Unicode] == 'false'
      prop[:isUnicode] = false
    end
    @inprop = @inprop + 1

    annotationTarget = className + "/" + item[:Name]
    parse_annotations(annotationTarget, item[:Annotation])
    set_description(annotationTarget, prop)

    return prop
  end

  def self.process_complextype(className, item = nil)
    prop = deep_copy(@struct[:property])
    prop[:name] = camelcase item[:Name]
    dt = get_type(item[:Type])
    prop[:isCollection] = true if item[:Type].start_with?('Collection(')
    prop[:dataType] = dt
    if @enum_objects.has_key?(dt.to_sym)
      prop[:enumName] = dt
      prop[:dataType] = "String"
    end
    if item[:Nullable] == 'false'
      prop[:isNullable] = false
    end
    if item[:Unicode] == 'false'
      prop[:isUnicode] = false
    end

    annotationTarget = className + "/" + item[:Name]
    parse_annotations(annotationTarget, item[:Annotation])
    set_description(annotationTarget, prop)

    return prop
  end

  # Process methods
  def self.process_method(item = nil, type = nil)
    mtd = deep_copy(@struct[:method])
    mtd[:name] = camelcase item[:Name].chomp(')')
    if type == 'function'
      mtd[:isFunction] = true
    else
      mtd[:isFunction] = false
    end
    mtd[:httpSuccessCode] = '200'
    if item.has_key?(:ReturnType)
      dt = get_type(item[:ReturnType][:Type])
      mtd[:isReturnTypeCollection] = true if item[:ReturnType][:Type].start_with?('Collection(')
      mtd[:returnType] = dt
      mtd[:isReturnNullable] = false if item[:ReturnType][:Nullable] == 'false'
    end
    # don't need to worry about param being hash as in that case, it'll just be the binding info.
    if item[:Parameter].is_a?(Array)
      mtd[:parameters] = []
      item[:Parameter].each_with_index do |p, i|
        parm = deep_copy(@struct[:parameter])
        next if i == 0

        @iparam = @iparam + 1
        parm[:name] = camelcase p[:Name]

        dtp = get_type(p[:Type])
        parm[:dataType] = dtp
        parm[:isCollection] = true if p[:Type].start_with?('Collection(')
        if p[:Nullable] == 'false'
          parm[:isNullable] = false
        end
        if p[:Unicode] == 'false'
          parm[:isUnicode] = false
        end

        mtd[:parameters].push parm
      end
    end

    # Get the entity name from the first parameter
    if item[:Parameter].is_a?(Array)
      enamef = item[:Parameter][0][:Type]
    elsif item[:Parameter].is_a?(Hash)
      enamef = item[:Parameter][:Type]
    end

    entity_name = enamef[(enamef.rindex('.') + 1)..-1]
    entity_name = entity_name.chomp(')')

    mtd = preserve_method_descriptions(entity_name, mtd)
    if @methods.has_key?(entity_name.downcase.to_sym)
      @methods[entity_name.downcase.to_sym].push mtd
    else
      @methods[entity_name.downcase.to_sym] = []
      @methods[entity_name.downcase.to_sym].push mtd
    end
    # create_examplefile(entity_name, mtd[:name])
    return
  end

  def self.fill_rest_path(parentPath = nil, entity = nil, isParentCollection = true)
    jsonCache = Hash.new
    fill_rest_path_internal(parentPath, entity, isParentCollection, jsonCache)
    write_json_from_cache(jsonCache)
  end

  def self.read_json_from_cache(jsonCache = nil, fullpath = nil)
    value = jsonCache[fullpath]

    if value.nil?
      value = JSON.parse(File.read(fullpath, :encoding => 'UTF-8'))
      jsonCache[fullpath] = value
    end

    return value;
  end

  def self.write_json_from_cache(jsonCache = nil)
    jsonCache.each_pair do |fullpath, object|
      File.open(fullpath, "w") do |f|
        f.write(JSON.pretty_generate object, :encoding => 'UTF-8')
      end
    end
  end

  def self.fill_rest_path_internal(parentPath = nil, entity = nil, isParentCollection = true, jsonCache = nil)
    fullpath = JSON_SOURCE_FOLDER + '/' + entity.downcase + '.json'
    ids = ''

    # append Id at the end.
    if File.file?(fullpath)
      object = read_json_from_cache(jsonCache, fullpath)

      # Check if the path already exists. This logic will eliminate deep redundant paths.
      # May lose some important ones.. but if this check is removed, some really deep/complex
      # logic needs to be inserted to add the
      object["restPath"].keys.each do |k|
        if parentPath.downcase.include?(k.to_s.downcase)
          return
        end
      end

      # Construct path and remove empty | and <> at the end (account for no key being available on the object.)
      object["properties"].each do |item|
        if item["isKey"]
          ids = ids + item["name"] + '|'
        end
      end
      # construct the path and
      if isParentCollection
        k = "#{parentPath}/{#{ids.chomp('|')}}".chomp('/{}')
      else
        k = parentPath
      end
      object["restPath"][k] = true
      return if object["properties"].length == 0

      object["properties"].each do |item|
        if item["isRelationship"]
          fill_rest_path_internal("#{k}/#{item["name"]}", item["dataType"], item["isCollection"], jsonCache)
        end
      end
      return
    else
      return
    end
  end
end