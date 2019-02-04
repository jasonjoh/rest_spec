require 'active_support'
require 'active_support/core_ext'
require 'json'
require 'logger'
# require 'FileUtils'

module SpecMaker
  JSON_BASE_FOLDER = "../jsonFiles/#{$options[:version]}/".freeze
  JSON_SOURCE_FOLDER = JSON_BASE_FOLDER + 'rest/'
  JSON_SETTINGS_FOLDER = JSON_BASE_FOLDER + 'settings/'
  JSON_PREV_SOURCE_FOLDER = JSON_BASE_FOLDER + 'rest_previous/'
  ENUMS = JSON_SETTINGS_FOLDER + 'restenums.json'
  ACTIONS = JSON_BASE_FOLDER + 'actions.json'
  ANNOTATIONS = JSON_SETTINGS_FOLDER + 'annotations.json'
  CSDL_LOCATION = "../data/#{$options[:version]}/".freeze

  JSON_EXAMPLE_FOLDER = JSON_BASE_FOLDER + 'examples/'
  BASETYPES = %w[Entity directoryObject Attachment Message OutlookItem Extension].freeze
  BASETYPES_ALLCASE = BASETYPES.map(&:downcase).concat BASETYPES

  ####
  # This is to address the special entityType:
  # <EntityType Name="Extension" BaseType="Microsoft.Graph.Entity" />
  # Here, there is no property or nav.prop defined for Extension. It simply
  # points back to the Entity. If more such cases arise, add an entry here.
  #
  ##
  BASETYPE_MAPPING = {
    'Extension' => 'extension',
    'extension' => 'extension'
  }.freeze
  # Load the template
  # JSON_TEMPLATE = "../jsonFiles/template/restresourcetemplate.json"
  # @template = JSON.parse(File.read(JSON_TEMPLATE, :encoding => 'UTF-8'), {:symbolize_names => true})

  # Load the structure
  JSON_STRUCTURE = '../jsonFiles/template/restresource_structures.json'.freeze
  @struct = JSON.parse(File.read(JSON_STRUCTURE, encoding: 'UTF-8'), symbolize_names: true)
  @template = @struct[:object]
  @service = @struct[:serviceSettings]

  Dir.mkdir(JSON_BASE_FOLDER) unless File.exist?(JSON_BASE_FOLDER)
  Dir.mkdir(CSDL_LOCATION) unless File.exist?(CSDL_LOCATION)

  Dir.mkdir(JSON_SOURCE_FOLDER) unless File.exist?(JSON_SOURCE_FOLDER)
  FileUtils.rm Dir.glob(JSON_SOURCE_FOLDER + '/*')
  Dir.mkdir(JSON_SETTINGS_FOLDER) unless File.exist?(JSON_SETTINGS_FOLDER)

  # Log file
  LOG_FOLDER = '../logs'.freeze
  Dir.mkdir(LOG_FOLDER) unless File.exist?(LOG_FOLDER)

  LOG_FILE = File.basename($PROGRAM_NAME, '.rb') + '.txt'
  File.delete("#{LOG_FOLDER}/#{LOG_FILE}") if File.exist?("#{LOG_FOLDER}/#{LOG_FILE}")
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
  @example_files_written = 0
  @annotations = {}

  def self.camelcase(str = '')
    str
  end

  def self.parse_annotations(target, annotations)
    return unless annotations

    if annotations.is_a?(Array)
      annotations.each do |annotation|
        parse_annotation(target, nil, annotation)
      end
    else
      parse_annotation(target, nil, annotations)
    end
  end

  def self.parse_annotation(target, term, annotation)
    # puts "-> Processing Annotation; Target: #{target}; Term: #{term}; Annotation: #{annotation}"

    if annotation[:Term]
      term = get_type(annotation[:Term]).downcase
    elsif annotation[:Property]
      term = term + '/' + annotation[:Property].downcase
    end

    @annotations[target] = {} unless @annotations[target]

    if annotation[:Bool]
      @annotations[target][term] = annotation[:Bool].casecmp('true').zero?
    elsif annotation[:String]
      @annotations[target][term] = annotation[:String]
    elsif annotation[:Record]
      if annotation[:Record][:PropertyValue]
        if annotation[:Record][:PropertyValue].is_a?(Array)
          annotation[:Record][:PropertyValue].each do |prop_val|
            parse_annotation(target, term, prop_val)
          end
        else
          parse_annotation(target, term, annotation[:Record][:PropertyValue])
        end
      end
    elsif annotation[:Collection]
      # TODO
    end
  end

  def self.set_description(target, item_to_set)
    target = target.downcase
    # puts "-> Getting Annotation; Target: #{target}"
    return unless @annotations[target]

    item_to_set[:description] = @annotations[target]['description'] if @annotations[target]['description']
  end

  ###
  # Create object_method-name.md file in lowercase.
  #
  #
  def self.create_examplefile(object_name = nil, method_name = nil)
    File.open(JSON_EXAMPLE_FOLDER + (object_name + '_' + method_name).downcase + '.md', 'w') do |f|
      f.write('##### Example', encoding: 'UTF-8')
      @example_files_written += 1
    end
  end

  ###
  # Create example files for object/collection.
  #
  #
  def self.create_auto_examplefiles(object_name = nil, is_collection)
    if !is_collection
      create_examplefile(object_name, 'auto_get')
      create_examplefile(object_name, 'auto_post')
      create_examplefile(object_name, 'auto_patch')
      create_examplefile(object_name, 'auto_put')
      create_examplefile(object_name, 'auto_delete')
    else
      create_examplefile(object_name, 'auto_list')
    end
  end

  ###
  # Create example files from array that contains many methods (1 per method)
  #
  #
  def self.create_basetype_examplefiles(methods = [], object_name = nil)
    methods.each do |item|
      create_examplefile(object_name, item[:name])
    end
  end

  ###
  # To prevent shallow copy errors, need to get a new object each time.
  #
  #
  def self.deep_copy(obj)
    Marshal.load(Marshal.dump(obj))
  end

  ###
  # Copy method description, display name, parameter descriptions, etc.
  #  from an existing JSON file from previous run.
  #
  #
  def self.preserve_method_descriptions(object_name = nil, method = nil)
    fullpath = JSON_PREV_SOURCE_FOLDER + object_name.downcase + '.json'
    return method unless File.file?(fullpath)

    prev_object = JSON.parse(File.read(fullpath, encoding: 'UTF-8'), symbolize_names: true)
    prev_methods = prev_object[:methods]
    prev_methods.each do |item|
      next unless item[:name] == method[:name]

      method[:description] = item[:description] unless item[:description].empty?
      method[:displayName] = item[:displayName] if item[:displayName] && !item[:displayName].empty?
      method[:prerequisites] = item[:prerequisites] unless item[:prerequisites].empty?
      method[:parameters].each do |param|
        item[:parameters].each do |old_param|
          if old_param[:name] == param[:name]
            param[:description] = old_param[:description] unless old_param[:description].empty?
          end
        end
      end
    end

    method
  end

  def self.preserve_object_property_descriptions(object_name = nil)
    fullpath = JSON_PREV_SOURCE_FOLDER + object_name.downcase + '.json'
    return unless File.file?(fullpath)

    prev_object = JSON.parse(File.read(fullpath, encoding: 'UTF-8'), symbolize_names: true)
    @json_object[:description] = prev_object[:description]
    prev_props = prev_object[:properties]
    prev_props.each do |item|
      @json_object[:properties].each do |current_prop|
        current_prop[:description] = item[:description] if item[:name] == current_prop[:name]
      end
    end
  end

  ###
  # Extract only the type name. Example: Collection(Microsoft.Graph.Recipient) to Recipient
  # and Microsoft.Graph.Recipient to Recipient
  #
  def self.get_type(type = nil)
    camelcase type[(type.rindex('.') + 1)..-1].chomp(')')
  end

  def self.merge_members(current = nil, base = nil)
    # if object_name != nil
    #   if base.is_a?(Hash)
    #     dt = get_type(base[:Type])
    #     return current if dt.downcase == object_name.downcase
    #   elsif base.is_a?(Array)
    #     base.each_with_index do |item, i|
    #       dt = get_type(item[:Type])
    #         base.delete_at(i) if dt == object_name
    #     end
    #   end
    # end

    arr = []
    return base if current.nil?

    if current.is_a?(Array)
      return current if base.nil?

      return current.concat base if base.is_a?(Array)

      return current.push base if base.is_a?(Hash)

    elsif current.is_a?(Hash)
      return current if base.nil?

      if base.is_a?(Array)
        arr = base
        return arr.push current
      elsif base.is_a?(Hash)
        arr.push base
        arr.push current
        return arr
      end
    end
  end

  def self.process_property(class_name, item = nil)
    prop = deep_copy(@struct[:property])
    prop[:name] = camelcase item[:Name]
    dt = get_type(item[:Type])
    prop[:isCollection] = true if item[:Type].start_with?('Collection(')
    prop[:dataType] = dt
    if @enum_objects.key?(dt.to_sym)
      prop[:enumName] = dt
      prop[:dataType] = 'string'
    end
    if @key_save.include?(item[:Name])
      prop[:isKey] = true
      prop[:isReadOnly] = true
    end
    prop[:isNullable] = false if item[:Nullable] == 'false'
    prop[:isUnicode] = false if item[:Unicode] == 'false'
    @iprop += 1

    annotation_target = class_name + '/' + item[:Name]
    parse_annotations(annotation_target, item[:Annotation])
    set_description(annotation_target, prop)

    prop
  end

  def self.process_navigation(class_name, item = nil)
    prop = deep_copy(@struct[:property])
    prop[:name] = camelcase item[:Name]
    prop[:isRelationship] = true
    dt = get_type(item[:Type])
    prop[:isCollection] = true if item[:Type].start_with?('Collection(')
    prop[:dataType] = dt
    prop[:isNullable] = true
    prop[:isReadOnly] = true
    prop[:isNullable] = false if item[:Nullable] == 'false'
    prop[:isUnicode] = false if item[:Unicode] == 'false'
    @inprop += 1

    annotation_target = class_name + '/' + item[:Name]
    parse_annotations(annotation_target, item[:Annotation])
    set_description(annotation_target, prop)

    prop
  end

  def self.process_complextype(class_name, item = nil)
    prop = deep_copy(@struct[:property])
    prop[:name] = camelcase item[:Name]
    dt = get_type(item[:Type])
    prop[:isCollection] = true if item[:Type].start_with?('Collection(')
    prop[:dataType] = dt
    if @enum_objects.key?(dt.to_sym)
      prop[:enumName] = dt
      prop[:dataType] = 'String'
    end
    prop[:isNullable] = false if item[:Nullable] == 'false'
    prop[:isUnicode] = false if item[:Unicode] == 'false'

    annotation_target = class_name + '/' + item[:Name]
    parse_annotations(annotation_target, item[:Annotation])
    set_description(annotation_target, prop)

    prop
  end

  # Process methods
  def self.process_method(item = nil, type = nil)
    mtd = deep_copy(@struct[:method])
    mtd[:name] = camelcase item[:Name].chomp(')')
    mtd[:isFunction] = type == 'function'
    mtd[:httpSuccessCode] = '200'
    if item.key?(:ReturnType)
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
        next if i.zero?

        @iparam += 1
        parm[:name] = camelcase p[:Name]

        dtp = get_type(p[:Type])
        parm[:dataType] = dtp
        parm[:isCollection] = true if p[:Type].start_with?('Collection(')
        parm[:isNullable] = false if p[:Nullable] == 'false'
        parm[:isUnicode] = false if p[:Unicode] == 'false'

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
    @methods[entity_name.downcase.to_sym] = [] unless @methods.key?(entity_name.downcase.to_sym)
    @methods[entity_name.downcase.to_sym].push mtd
    # create_examplefile(entity_name, mtd[:name])
    nil
  end

  def self.fill_rest_path(parent_path = nil, entity = nil, is_parent_collection = true)
    json_cache = {}
    fill_rest_path_internal(parent_path, entity, is_parent_collection, json_cache)
    write_json_from_cache(json_cache)
  end

  def self.read_json_from_cache(json_cache = nil, fullpath = nil)
    value = json_cache[fullpath]

    if value.nil?
      value = JSON.parse(File.read(fullpath, encoding: 'UTF-8'))
      json_cache[fullpath] = value
    end

    value
  end

  def self.write_json_from_cache(json_cache = nil)
    json_cache.each_pair do |fullpath, object|
      File.open(fullpath, 'w') do |f|
        f.write(JSON.pretty_generate(object, encoding: 'UTF-8'))
      end
    end
  end

  def self.fill_rest_path_internal(parent_path = nil, entity = nil, is_parent_collection = true, json_cache = nil)
    fullpath = JSON_SOURCE_FOLDER + '/' + entity.downcase + '.json'
    ids = ''

    # append Id at the end.
    return unless File.file?(fullpath)

    object = read_json_from_cache(json_cache, fullpath)

    # Check if the path already exists. This logic will eliminate deep redundant paths.
    # May lose some important ones.. but if this check is removed, some really deep/complex
    # logic needs to be inserted to add the
    object['restPath'].keys.each do |k|
      # rubocop:disable Lint/NonLocalExitFromIterator
      return if parent_path.downcase.include?(k.to_s.downcase)
      # rubocop:enable Lint/NonLocalExitFromIterator
    end

    # Construct path and remove empty | and <> at the end (account for no key being available on the object.)
    object['properties'].each do |item|
      ids = ids + item['name'] + '|' if item['isKey']
    end
    # construct the path and
    k = if is_parent_collection
          "#{parent_path}/{#{ids.chomp('|')}}".chomp('/{}')
        else
          parent_path
        end
    object['restPath'][k] = true
    return if object['properties'].empty?

    object['properties'].each do |item|
      next if item['dataType'].casecmp('user').zero?

      fill_rest_path_internal("#{k}/#{item['name']}", item['dataType'], item['isCollection'], json_cache) if item['isRelationship']
    end
  end
end
