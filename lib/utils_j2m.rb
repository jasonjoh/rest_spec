require 'FileUtils'

module SpecMaker
	# Initialize
	JSON_BASE_FOLDER = "../jsonFiles/"
	JSON_SOURCE_FOLDER = "../jsonFiles/rest/"
	ENUMS = JSON_BASE_FOLDER + '/settings/restenums.json'
	MARKDOWN_BASE_FOLDER = "../markdowns/"
	MARKDOWN_RESOURCE_FOLDER = "../markdowns/resources/"
	MARKDOWN_API_FOLDER = "../markdowns/api/"
	EXAMPLES_FOLDER = JSON_SOURCE_FOLDER + "examples/"
	JSON_EXAMPLE_FOLDER = "../jsonFiles/examples/"
	ANNOTATIONS = JSON_BASE_FOLDER + 'settings/annotations.json'
	SERVER = 'https://graph.microsoft.com/v1.0'
	HEADER1 = '# '
	HEADER2 = '## '
	HEADER3 = '### '
	HEADER4 = '#### '
	HEADER5 = '##### '
	BACKTOMETHOD = '[Back](#methods)'
	NEWLINE = "\n"
	BACKTOPROPERTY = NEWLINE + '[Back](#properties)'
	PIPE = '|'
	TWONEWLINES = "\n\n"

	TABLE_2ND_LINE =  "|:---------------|:--------|:----------|" + NEWLINE
	TABLE_2ND_LINE_2COL =  "|:---------------|:----------|" + NEWLINE
	PROPERTY_HEADER = "| Property	   | Type	|Description|" + NEWLINE
	PARAM_HEADER = "| Parameter	   | Type	|Description|" + NEWLINE
	HTTP_HEADER = "| Name       | Description|" + NEWLINE
	RELATIONSHIP_HEADER = "| Relationship | Type	|Description|" + NEWLINE
	TASKS_HEADER = "| Method		   | Return Type	|Description|" + NEWLINE

	PREREQ = HEADER2 + "Permissions" + NEWLINE + "One of the following permissions is required to call this API. To learn more, including how to choose permissions, see [Permissions](../../../concepts/permissions_reference.md)." + NEWLINE + NEWLINE + "|Permission type      | Permissions (from least to most privileged)              |" + NEWLINE + "|:--------------------|:---------------------------------------------------------|" + NEWLINE + "|Delegated (work or school account) |    |" + NEWLINE + "|Delegated (personal Microsoft account) |    |" + NEWLINE + "|Application |  | " + NEWLINE + NEWLINE

	QRY_HEADER = "|Name|Value|Description|"
	QRY_2nd_LINE = "|:---------------|:--------|:-------|"
	QRY_EXPAND = "|$expand|string|Comma-separated list of relationships to expand and include in the response. "
	QRY_FILTER  = "|$filter|string|Filter string that lets you filter the response based on a set of criteria.|"
	QRY_ORDERBY = "|$orderby|string|Comma-separated list of properties that are used to sort the order of items in the response collection.|"
	QRY_SELECT = "|$select|string|Comma-separated list of properties to include in the response.|"
	QRY_SKIPTOKEN = "|$skipToken|string|Paging token that is used to get the next set of results.|"
	QRY_TOP = "|$top|int|The number of items to return in a result set.|"
	QRY_SKIP = "|$skip|int|The number of items to skip in a result set.|"
	QRY_COUNT = "|$count|none|The count of related entities can be requested by specifying the $count query option.|"

	# HTTP_HEADER_SAMPLE = "| Authorization  | Bearer {code}|" + NEWLINE + "| Workbook-Session-Id  | Workbook session Id that determines if changes are persisted or not. Optional.|"
	HTTP_HEADER_SAMPLE = "| Authorization  | Bearer {code}|"

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
						conversationthread recipient privilegedroleassignment item]

	TIMESTAMP_DESC = %q{The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 would look like this: `'2014-01-01T00:00:00Z'`}

	# Load the structure
	JSON_STRUCTURE = "../jsonFiles/template/restresource_structures.json"
	@struct = JSON.parse(File.read(JSON_STRUCTURE, :encoding => 'UTF-8'), {:symbolize_names => true})
	@template = @struct[:object]
	@service = @struct[:serviceSettings]
	@mdresource = @struct[:mdresource]
	@mdrequest = @struct[:mdrequest]
	@mdresponse = @struct[:mdresponse]
	@mdignore = @struct[:mdignore]
	@mdpageannotate = @struct[:mdpageannotate]
	@serviceroot = []

	HTTP_CODES = {
					"200" => "OK",
					"201" => "Created",
					"202" => "Accepted",
					"203" => "Non-Authoritative Information",
					"204" => "No Content",
					"205" => "Reset Content",
					"206" => "Partial Content",
					"300" => "Multiple Choices",
					"301" => "Moved Permanently",
					"302" => "Found",
					"303" => "See Other",
					"304" => "Not Modified",
					"306" => "Switch Proxy",
					"307" => "Temporary Redirect",
					"308" => "Resume Incomplete"
				}

	#UUID_DATE = "<!-- uuid: " + SecureRandom.uuid  + "\n" + Time.now.utc.to_s + " -->"
	UUID_DATE = "<!-- uuid: " + "8fcb5dbc-d5aa-4681-8e31-b001d5168d79"  + "\n" + "2015-10-25 14:57:30 UTC" + " -->"

	# Log file
	LOG_FOLDER = '../logs'
	Dir.mkdir(LOG_FOLDER) unless File.exists?(LOG_FOLDER)

	LOG_FILE = File.basename($PROGRAM_NAME, ".rb") + ".txt";
	if File.exists?("#{LOG_FOLDER}/#{LOG_FILE}")
		File.delete("#{LOG_FOLDER}/#{LOG_FILE}")
	end
	@logger = Logger.new("#{LOG_FOLDER}/#{LOG_FILE}")
	@logger.level = Logger::DEBUG
	# End log file

#

	Dir.mkdir(MARKDOWN_BASE_FOLDER) unless File.exists?(MARKDOWN_BASE_FOLDER)

	Dir.mkdir(MARKDOWN_RESOURCE_FOLDER) unless File.exists?(MARKDOWN_RESOURCE_FOLDER)
	FileUtils.rm Dir.glob(MARKDOWN_RESOURCE_FOLDER + '/*')

	Dir.mkdir(MARKDOWN_API_FOLDER) unless File.exists?(MARKDOWN_API_FOLDER)
	FileUtils.rm Dir.glob(MARKDOWN_API_FOLDER + '/*')

#


	###
	# To prevent shallow copy errors, need to get a new object each time.
	#
	#
	def self.deep_copy(o)
		Marshal.load(Marshal.dump(o))
	end

	@resources_files_created = 0
	@get_list_files_created = 0
	@patch_files_created = 0
	@method_files_created = 0
	@ientityset = 0
	@list_from_rel = 0


	# Create markdown folder if it doesn't already exist
	Dir.mkdir(MARKDOWN_RESOURCE_FOLDER) unless File.exists?(MARKDOWN_RESOURCE_FOLDER)

	if !File.exists?(JSON_SOURCE_FOLDER)
		@logger.fatal("JSON Resource File folder does not exist. Aborting")
		abort("*** FATAL ERROR *** Input JSON resource folder: #{JSON_SOURCE_FOLDER} doesn't exist. Correct and re-run." )
	end

	if !File.exists?(EXAMPLES_FOLDER)
		@logger.warn("API examples folder does not exist")
	end

	##
	# Load up all the known existing annotations.
	###
	@annotations = {}

	begin
		@annotations = JSON.parse File.read(ANNOTATIONS, :encoding => 'UTF-8')
	rescue => err
		@logger.warn("JSON Annotations input file doesn't exist: #{@current_object}")
	end

	##
	# Load up all the known existing enums.
	###
	@enumHash = {}

	begin
		@enumHash = JSON.parse File.read(ENUMS, :encoding => 'UTF-8')
	rescue => err
		@logger.warn("JSON Enumeration input file doesn't exist: #{@current_object}")
	end

	@mdlines = []
	@resource = ''

	def self.uncapitalize (str="")
		if str.length > 0
			str[0, 1].downcase + str[1..-1]
		else
			str
		end
	end

	def self.uuid_date
		return UUID_DATE
	end

	def self.get_create_description(objectName=nil)
		createDescription = ''
		fullpath = JSON_SOURCE_FOLDER + '/' + objectName.downcase + '.json'
		if File.file?(fullpath)
			object = JSON.parse(File.read(fullpath, :encoding => 'UTF-8'), {:symbolize_names => true})
			createDescription = object[:createDescription]
		end
		return createDescription
	end

	def self.assign_value (dataType=nil, name='')

		if dataType.downcase.start_with?('extension')
			return {}
		end

		if NUMERICTYPES.include? dataType.downcase
			return 99
		elsif DATETYPES.include? dataType.downcase
			return "datetime-value"
		elsif %w[Url url].include? dataType.downcase
			return"url-value"
		elsif %w[Boolean boolean Bool bool ].include? dataType
			return true
		elsif SIMPLETYPES.include? dataType.downcase
			return "#{name}-value"
		else
			return dump_complex_type(dataType)
		end
	end

	def self.dump_complex_type(ct=nil)
		model={}
		fullpath = JSON_SOURCE_FOLDER + '/' + ct.downcase + '.json'
		if File.file?(fullpath)
			object = JSON.parse(File.read(fullpath, :encoding => 'UTF-8'), {:symbolize_names => true})
			object[:properties].each do |item|
				if item[:name].downcase.start_with?('extension')
					next
					#model[item[:name]] = {}
				else
					model[item[:name]] = assign_value2(item[:dataType], item[:name], item[:isRelationship])
					if item[:isCollection]
						model[item[:name]] = [model[item[:name]]]
					end
				end
				# end
			end
		end

		return model
	end

	def self.assign_value2 (dataType=nil, name='', isRel=false)

		if dataType.downcase.start_with?('extension')
			return {}
		end

		if dataType.downcase.start_with?('post')
			return {}
		end

		if NUMERICTYPES.include? dataType.downcase
			return 99
		elsif DATETYPES.include? dataType.downcase
			return "datetime-value"
		elsif %w[Url url].include? dataType.downcase
			return"url-value"
		elsif %w[Boolean boolean Bool bool ].include? dataType.downcase
			return true
		elsif SIMPLETYPES.include? dataType.downcase
			return "#{name}-value"
		else
			return dump_complex_type(dataType)
		end
	end

	def self.get_json_model_method (objectName=nil, collFlag=false, includeKey=true, openTypeReq = false)
		model = {}
		if SIMPLETYPES.include? objectName
			model[:value] = assign_value(objectName, objectName)
			if collFlag
				model[:value] = [assign_value(objectName, objectName)]
			else
				model[:value] = assign_value(objectName, objectName)
			end
			return JSON.pretty_generate model
		end
		isOpenType = false
		fullpath = JSON_SOURCE_FOLDER + '/' + objectName.downcase + '.json'
		if File.file?(fullpath)
			object = JSON.parse(File.read(fullpath, :encoding => 'UTF-8'), {:symbolize_names => true})
			if object[:isOpenType]
				isOpenType = true
			end
			object[:properties].each_with_index do |item, i|
				next if item[:isRelationship]
				next if i > 5
				if !includeKey
					next if item[:isKey]
				end

				if item[:name].downcase.start_with?('extension')
					model[item[:name]] = {}
				else
					model[item[:name]] = assign_value(item[:dataType], item[:name])
				end
				if item[:isCollection]
					model[item[:name]] = [model[item[:name]]]
				end
			end
		end
		if collFlag
			model = {"value" => [model]}
		end
		if isOpenType && openTypeReq
			model = { "#{objectName}" => model }
		end
		return JSON.pretty_generate model
	end

	def self.get_json_model_params(params=[])

		model={}

		params.each do |item|
			model[item[:name]] = assign_value(item[:dataType], item[:name])
			if item[:isCollection]
				model[item[:name]] = [model[item[:name]]]
			end
		end
		return JSON.pretty_generate model
	end

	def self.get_json_model (properties=[])
		model = {}
		properties.each do |item|
			next if item[:isRelationship]

			if NUMERICTYPES.include? item[:dataType].downcase
				model[item[:name]] = 1024
			elsif DATETYPES.include? item[:dataType].downcase
				model[item[:name]] = "String (timestamp)"
			elsif %w[Url url].include? item[:dataType]
				model[item[:name]] = "url"
			elsif %w[Boolean boolean Bool bool ].include? item[:dataType]
				model[item[:name]] = true
			elsif SIMPLETYPES.include? item[:dataType].downcase
				model[item[:name]] = "#{item[:dataType]}"
			else
				model[item[:name]] = { "@odata.type" => "#{@service[:namespace]}.#{item[:dataType]}"}
			end

			if item[:isKey]
				model[item[:name]] = model[item[:name]] + ' (identifier)'
			end
			if %w['eTag', 'cTag', 'etag', 'ctag'].include?(item[:name])
				model[item[:name]] = model[item[:name]] + ' (etag)'
			end
			if item[:isCollection]
				model[item[:name]] = [model[item[:name]]]
			end
		end
		return JSON.pretty_generate model
	end

	def self.get_json_model_pretext (objectName="", properties=[])
		model = deep_copy(@mdresource)
		model["@odata.type"] = "#{@service[:namespace]}.#{objectName}"
		properties.each do |item|

			next if item[:isRelationship]

			if item[:isNullable] || item[:isRelationship]
				model[:optionalProperties].push item[:name]
			end
		end
		return "<!-- " + (JSON.pretty_generate model) + "-->"
	end

	def self.pretty_json(input = nil)
		output = ""
		save = ""
		input.split("\n").each do |line|
			if (line[0..0] == '{')
				output = output  + line
				next
			end
			if (line[0..0] == '}')
				output = output + save + NEWLINE
				save = "" # not required...
				output = output +  line
				next
			end
			if line[2..2] == '"'
				output = output + save + NEWLINE
				output = output + line
				save = ""
				next
			end
			save = save + line.strip
		end
		return output
	end

	def self.get_json_page_annotation (description=nil)
		model = deep_copy(@mdpageannotate)
		model[:description] = description
		return "<!-- " + (JSON.pretty_generate model) + "-->"
	end

	def self.get_json_request_pretext (name=nil)
		model = deep_copy(@mdrequest)
		model[:name] = name
		return "<!-- " + (JSON.pretty_generate model) + "-->"

	end

	def self.get_json_response_pretext (type=nil, isArray=false)
		model = deep_copy(@mdresponse)
		if type == nil || type == 'none'
		else
			if SIMPLETYPES.include? type
				model["@odata.type"] = type
			else
				model["@odata.type"] = "#{@service[:namespace]}.#{type}"
			end
			model[:isCollection] = true if isArray
		end
		return "<!-- " + (JSON.pretty_generate model) + " -->"
	end

# module end
end
