require 'FileUtils'

module SpecMaker
  # Initialize
  JSON_BASE_FOLDER = "../jsonFiles/#{$options[:version]}/".freeze
  JSON_SOURCE_FOLDER = JSON_BASE_FOLDER + 'rest/'
  JSON_SETTINGS_FOLDER = JSON_BASE_FOLDER + 'settings/'
  ENUMS = JSON_SETTINGS_FOLDER + 'restenums.json'
  ACTIONS = JSON_BASE_FOLDER + 'actions.json'
  ANNOTATIONS = JSON_SETTINGS_FOLDER + 'annotations.json'

  MARKDOWN_BASE_FOLDER = "../markdown/#{$options[:version]}/".freeze
  MARKDOWN_RESOURCE_FOLDER = MARKDOWN_BASE_FOLDER + 'resources/'
  MARKDOWN_API_FOLDER = MARKDOWN_BASE_FOLDER + 'api/'
  EXAMPLES_FOLDER = JSON_SOURCE_FOLDER + 'examples/'
  JSON_EXAMPLE_FOLDER = JSON_BASE_FOLDER + 'examples/'
  SERVER = "https://graph.microsoft.com/#{$options[:version]}".freeze
  HEADER1 = '# '.freeze
  HEADER2 = '## '.freeze
  HEADER3 = '### '.freeze
  HEADER4 = '#### '.freeze
  HEADER5 = '##### '.freeze
  # BACKTOMETHOD = '[Back](#methods)'
  NEWLINE = "\n".freeze
  # BACKTOPROPERTY = NEWLINE + '[Back](#properties)'
  PIPE = '|'.freeze
  TWONEWLINES = "\n\n".freeze

  # Alert styles
  ALERT_NOTE = '> **Note:** '.freeze
  ALERT_IMPORTANT = '> **Important:** '.freeze
  # ALERT_NOTE = "> [!NOTE]\n> "
  # ALERT_IMPORTANT = "> [!IMPORTANT]\n> "

  TABLE_2ND_LINE =       '|:-------------|:------------|:------------|' + NEWLINE
  PROPERTY_HEADER =      '| Property     | Type        | Description |' + NEWLINE
  PARAM_HEADER =         '| Parameter    | Type        | Description |' + NEWLINE
  RELATIONSHIP_HEADER =  '| Relationship | Type        | Description |' + NEWLINE
  TASKS_HEADER =         '| Method       | Return Type | Description |' + NEWLINE

  TABLE_2ND_LINE_2COL =  '|:--------------|:--------------|' + NEWLINE
  HTTP_HEADER =          '| Name          | Description   |' + NEWLINE
  # HTTP_HEADER_SAMPLE = "| Authorization | Bearer {code} |" + NEWLINE + "| Workbook-Session-Id  | Workbook session Id that determines if changes are persisted or not. Optional.|"
  HTTP_HEADER_SAMPLE =   '| Authorization | Bearer {code} |'.freeze
  ENUM_HEADER =          '| Member       | Value       |' + NEWLINE

  PREREQ = HEADER2 + 'Permissions' + TWONEWLINES + 'One of the following permissions is required to call this API. To learn more, including how to choose permissions, see [Permissions](/graph/permissions-reference).' + TWONEWLINES + \
           '|Permission type                        | Permissions (from least to most privileged) |' + NEWLINE + \
           '|:--------------------------------------|:--------------------------------------------|' + NEWLINE + \
           '|Delegated (work or school account)     | Not supported. |' + NEWLINE + \
           '|Delegated (personal Microsoft account) | Not supported. |' + NEWLINE + \
           '|Application                            | Not supported. |' + TWONEWLINES

  QRY_HEADER = '|Name|Value|Description|'.freeze
  # QRY_2ND_LINE = '|:---------------|:--------|:-------|'.freeze
  QRY_EXPAND = '|$expand|string|Comma-separated list of relationships to expand and include in the response. '.freeze
  QRY_FILTER  = '|$filter|string|Filter string that lets you filter the response based on a set of criteria.|'.freeze
  QRY_ORDERBY = '|$orderby|string|Comma-separated list of properties that are used to sort the order of items in the response collection.|'.freeze
  QRY_SELECT = '|$select|string|Comma-separated list of properties to include in the response.|'.freeze
  QRY_SKIPTOKEN = '|$skipToken|string|Paging token that is used to get the next set of results.|'.freeze
  QRY_TOP = '|$top|int|The number of items to return in a result set.|'.freeze
  QRY_SKIP = '|$skip|int|The number of items to skip in a result set.|'.freeze
  QRY_COUNT = '|$count|none|The count of related entities can be requested by specifying the $count query option.|'.freeze

  odata_types = %w[Binary Boolean Byte Date DateTimeOffset Decimal Double Duration
                   Guid Int Int16 Int32 Int64 SByte Single Stream String TimeOfDay
                   Geography GeographyPoint GeographyLineString GeographyPolygon GeographyMultiPoint
                   GeographyMultiLineString GeographyMultiPolygon GeographyCollection Geometry
                   GeometryPoint GeometryLineString GeometryPolygon GeometryMultiPoint GeometryMultiLineString
                   GeometryMultiPolygon GeometryCollection Octet-Stream Octet Url Json]

  numeric_types = %w[Byte Decimal Double Int Int16 Int32 Int64]
  datetime_types = %w[Date DateTimeOffset Duration TimeOfDay]

  SIMPLETYPES = odata_types.concat odata_types.map(&:downcase)
  NUMERICTYPES = numeric_types.concat numeric_types.map(&:downcase)
  DATETYPES = datetime_types.concat datetime_types.map(&:downcase)

  # Below objects appear as the generic datatypes of collections.
  # e.g: <NavigationProperty Name="owners" Type="Collection(Microsoft.Graph.DirectoryObject)" />
  # For POST /Collection, we want to use a name that's sensible such as
  # Add Owner or Create Owner instead of Add DirectoryObject. Hence, if the
  # collection(datatype) happens to be one the below, we'll use the name in the API name.
  POST_NAME_MAPPING = %w[recipient directoryobject photo
                         conversationthread recipient privilegedroleassignment item].freeze

  TIMESTAMP_DESC = "The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 would look like this: `'2014-01-01T00:00:00Z'`".freeze

  # Load the structure
  JSON_STRUCTURE = '../jsonFiles/template/restresource_structures.json'.freeze
  @struct = JSON.parse(File.read(JSON_STRUCTURE, encoding: 'UTF-8'), symbolize_names: true)
  @template = @struct[:object]
  @service = @struct[:serviceSettings]
  @mdresource = @struct[:mdresource]
  @mdrequest = @struct[:mdrequest]
  @mdresponse = @struct[:mdresponse]
  @mdignore = @struct[:mdignore]
  @mdpageannotate = @struct[:mdpageannotate]
  @serviceroot = []

  HTTP_CODES = {
    '200' => 'OK',
    '201' => 'Created',
    '202' => 'Accepted',
    '203' => 'Non-Authoritative Information',
    '204' => 'No Content',
    '205' => 'Reset Content',
    '206' => 'Partial Content',
    '300' => 'Multiple Choices',
    '301' => 'Moved Permanently',
    '302' => 'Found',
    '303' => 'See Other',
    '304' => 'Not Modified',
    '306' => 'Switch Proxy',
    '307' => 'Temporary Redirect',
    '308' => 'Resume Incomplete'
  }.freeze

  # UUID_DATE = "<!-- uuid: " + SecureRandom.uuid  + "\n" + Time.now.utc.to_s + " -->"
  UUID_DATE = '<!-- uuid: ' + '16cd6b66-4b1a-43a1-adaf-3a886856ed98' + "\n" + '2019-02-04 14:57:30 UTC' + ' -->'

  # Log file
  LOG_FOLDER = '../logs'.freeze
  Dir.mkdir(LOG_FOLDER) unless File.exist?(LOG_FOLDER)

  LOG_FILE = File.basename($PROGRAM_NAME, '.rb') + '.txt'
  File.delete("#{LOG_FOLDER}/#{LOG_FILE}") if File.exist?("#{LOG_FOLDER}/#{LOG_FILE}")
  @logger = Logger.new("#{LOG_FOLDER}/#{LOG_FILE}")
  @logger.level = Logger::DEBUG
  # End log file

  Dir.mkdir('../markdown') unless File.exist?('../markdown')
  Dir.mkdir(MARKDOWN_BASE_FOLDER) unless File.exist?(MARKDOWN_BASE_FOLDER)

  Dir.mkdir(MARKDOWN_RESOURCE_FOLDER) unless File.exist?(MARKDOWN_RESOURCE_FOLDER)
  FileUtils.rm Dir.glob(MARKDOWN_RESOURCE_FOLDER + '/*')

  Dir.mkdir(MARKDOWN_API_FOLDER) unless File.exist?(MARKDOWN_API_FOLDER)
  FileUtils.rm Dir.glob(MARKDOWN_API_FOLDER + '/*')

  ###
  # To prevent shallow copy errors, need to get a new object each time.
  #
  #
  def self.deep_copy(object)
    Marshal.load(Marshal.dump(object))
  end

  @resources_files_created = 0
  @get_list_files_created = 0
  @patch_files_created = 0
  @method_files_created = 0
  @ientityset = 0
  @list_from_rel = 0

  # Create markdown folder if it doesn't already exist
  Dir.mkdir(MARKDOWN_RESOURCE_FOLDER) unless File.exist?(MARKDOWN_RESOURCE_FOLDER)

  unless File.exist?(JSON_SOURCE_FOLDER)
    @logger.fatal('JSON Resource File folder does not exist. Aborting')
    abort("*** FATAL ERROR *** Input JSON resource folder: #{JSON_SOURCE_FOLDER} doesn't exist. Correct and re-run.")
  end

  @logger.warn('API examples folder does not exist') unless File.exist?(EXAMPLES_FOLDER)

  ##
  # Load up all the known existing annotations.
  ###
  @annotations = {}

  begin
    @annotations = JSON.parse File.read(ANNOTATIONS, encoding: 'UTF-8')
  rescue StandardError
    @logger.warn("JSON Annotations input file doesn't exist: #{@current_object}")
  end

  ##
  # Load up all the known existing enums.
  ###
  @enum_hash = {}

  begin
    @enum_hash = JSON.parse File.read(ENUMS, encoding: 'UTF-8')
  rescue StandardError
    @logger.warn("JSON Enumeration input file doesn't exist: #{@current_object}")
  end

  @mdlines = []
  @resource = ''

  def self.uncapitalize(str = '')
    if str.empty?
      str
    else
      str[0, 1].downcase + str[1..-1]
    end
  end

  def self.uuid_date
    UUID_DATE
  end

  def self.get_create_description(object_name = nil, use_name = nil)
    create_description = ''
    fullpath = JSON_SOURCE_FOLDER + '/' + object_name.downcase + '.json'
    if File.file?(fullpath)
      object = JSON.parse(File.read(fullpath, encoding: 'UTF-8'), symbolize_names: true)
      create_description = object[:createDescription]
    end
    create_description = "Use this API to create a new #{use_name || object_name}." if create_description.empty?
    create_description
  end

  def self.assign_value(data_type = nil, name = '')
    return {} if data_type.downcase.start_with?('extension')

    return 99 if NUMERICTYPES.include? data_type.downcase

    return 'datetime-value' if DATETYPES.include? data_type.downcase

    return 'url-value' if %w[Url url].include? data_type.downcase

    return true if %w[Boolean boolean Bool bool].include? data_type

    return "#{name}-value" if SIMPLETYPES.include? data_type.downcase

    # TODO: This causes stack errors with too many levels, fix this
    dump_complex_type(data_type)
  end

  def self.dump_complex_type(complex_type = nil)
    model = {}
    fullpath = JSON_SOURCE_FOLDER + '/' + complex_type.downcase + '.json'
    if File.file?(fullpath)
      begin
        object = JSON.parse(File.read(fullpath, encoding: 'UTF-8'), symbolize_names: true)
        object[:properties].each do |item|
          next if item[:name].downcase.start_with?('extension')

          model[item[:name]] = assign_value2(item[:dataType], item[:name], item[:isRelationship])
          next unless item[:isCollection]

          model[item[:name]] = if model[item[:name]].empty?
                                 []
                               else
                                 [model[item[:name]]]
                               end
        end
      rescue SystemStackError
        model[:err] = 'SystemStackError'
      end
    end

    model
  end

  def self.assign_value2(data_type = nil, name = '', is_relation = false)
    return {} if is_relation

    return {} if data_type.downcase.start_with?('extension')

    return {} if data_type.downcase.start_with?('post')

    return {} if data_type.downcase.start_with?('extension')

    return 99 if NUMERICTYPES.include? data_type.downcase

    return 'datetime-value' if DATETYPES.include? data_type.downcase

    return 'url-value' if %w[Url url].include? data_type.downcase

    return true if %w[Boolean boolean Bool bool].include? data_type

    return "#{name}-value" if SIMPLETYPES.include? data_type.downcase

    # TODO: This causes stack errors with too many levels, fix this
    dump_complex_type(data_type)
  end

  def self.get_json_model_method(object_name = nil, is_collection = false, include_key = true, open_type_req = false)
    model = {}
    if SIMPLETYPES.include? object_name
      model[:value] = assign_value(object_name, object_name)
      model[:value] = if is_collection
                        [assign_value(object_name, object_name)]
                      else
                        assign_value(object_name, object_name)
                      end
      return JSON.pretty_generate model
    end
    is_open_type = false
    fullpath = JSON_SOURCE_FOLDER + '/' + object_name.downcase + '.json'
    if File.file?(fullpath)
      object = JSON.parse(File.read(fullpath, encoding: 'UTF-8'), symbolize_names: true)
      is_open_type = true if object[:isOpenType]
      object[:properties].each_with_index do |item, i|
        next if item[:isRelationship]
        next if i > 5

        unless include_key
          next if item[:isKey]
        end

        model[item[:name]] = if item[:name].downcase.start_with?('extension')
                               {}
                             else
                               assign_value(item[:dataType], item[:name])
                             end
        model[item[:name]] = [model[item[:name]]] if item[:isCollection]
      end
    end
    model = { 'value' => [model] } if is_collection
    model = { object_name.to_s => model } if is_open_type && open_type_req
    JSON.pretty_generate model, max_nesting: false
  end

  def self.get_json_model_params(params = [])
    model = {}

    params.each do |item|
      model[item[:name]] = assign_value(item[:dataType], item[:name])
      model[item[:name]] = [model[item[:name]]] if item[:isCollection]
    end

    JSON.pretty_generate model, max_nesting: false
  end

  def self.get_json_model(properties = [])
    model = {}
    properties.each do |item|
      next if item[:isRelationship]

      model[item[:name]] = if NUMERICTYPES.include? item[:dataType].downcase
                             1024
                           elsif DATETYPES.include? item[:dataType].downcase
                             'String (timestamp)'
                           elsif %w[Url url].include? item[:dataType]
                             'url'
                           elsif %w[Boolean boolean Bool bool].include? item[:dataType]
                             true
                           elsif SIMPLETYPES.include? item[:dataType].downcase
                             (item[:dataType]).to_s
                           else
                             { '@odata.type' => "#{@service[:namespace]}.#{item[:dataType]}" }
                           end

      model[item[:name]] = model[item[:name]] + ' (identifier)' if item[:isKey]
      model[item[:name]] = model[item[:name]] + ' (etag)' if %w[eTag cTag etag ctag].include?(item[:name])
      model[item[:name]] = [model[item[:name]]] if item[:isCollection]
    end
    JSON.pretty_generate model
  end

  def self.get_json_model_pretext(object_name = '', properties = [], base_type = '')
    model = deep_copy(@mdresource)
    model['@odata.type'] = "#{@service[:namespace]}.#{object_name}"
    model['baseType'] = base_type
    properties.each do |item|
      next if item[:isRelationship]

      model[:optionalProperties].push item[:name] if item[:isNullable] || item[:isRelationship]

      model['keyProperty'] = item[:name] if item[:isKey]
    end
    '<!-- ' + (JSON.pretty_generate model) + '-->'
  end

  def self.pretty_json(input = nil)
    output = ''
    save = ''
    input.split("\n").each do |line|
      if line[0..0] == '{'
        output += line
        next
      end
      if line[0..0] == '}'
        output = output + save + NEWLINE
        save = '' # not required...
        output += line
        next
      end
      if line[2..2] == '"'
        output = output + save + NEWLINE
        output += line
        save = ''
        next
      end
      save += line.strip
    end
    output
  end

  def self.get_json_page_annotation(description = nil)
    model = deep_copy(@mdpageannotate)
    model[:description] = description
    '<!-- ' + (JSON.pretty_generate model) + '-->'
  end

  def self.get_json_request_pretext(name = nil)
    model = deep_copy(@mdrequest)
    model[:name] = name
    '<!-- ' + (JSON.pretty_generate model) + '-->'
  end

  def self.get_json_response_pretext(type = nil, is_array = false)
    model = deep_copy(@mdresponse)
    if type.nil? || type == 'none'
    else
      model['@odata.type'] = if SIMPLETYPES.include? type
                               type
                             else
                               "#{@service[:namespace]}.#{type}"
                             end
      model[:isCollection] = true if is_array
    end
    '<!-- ' + (JSON.pretty_generate model) + ' -->'
  end

  def self.sanitize_file_name(file_name)
    file_name.tr('_', '-')
  end

  # module end
end
