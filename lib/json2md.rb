###
# This program reads the JSON specification files and creates the Markdown files (minus the examples).
# Location: https://github.com/sumurthy/md_apispec
###
require 'pathname'
require 'logger'
require 'json'
require 'securerandom'

module SpecMaker

	require_relative 'utils_j2m'

	def self.gen_example (type=nil, method={}, pathAppend=nil)
		example_lines = []
		example_lines.push HEADER2 + "Example" + NEWLINE
		case type
		when 'auto_post'
			example_lines.push HEADER5 + "Request" + NEWLINE
			example_lines.push "The following is an example of the request." + NEWLINE
			example_lines.push get_json_request_pretext("create_#{method[:returnType]}_from_#{@jsonHash[:name]}".downcase) + NEWLINE
			example_lines.push '```http' + NEWLINE
			httpSyntax = get_syntax('auto_post', top_one_restpath, pathAppend, nil, SERVER)
			example_lines.push httpSyntax.join("\n") + NEWLINE
			modeldump = get_json_model_method(method[:returnType], false, false, true)
			example_lines.push "Content-type: application/json" + NEWLINE
			example_lines.push "Content-length: #{modeldump.length.to_s}" + TWONEWLINES
			example_lines.push modeldump + NEWLINE
			example_lines.push "```" + NEWLINE

			example_lines.push "In the request body, supply a JSON representation of [#{method[:returnType]}](../resources/#{method[:returnType].downcase}.md) object." + NEWLINE

			example_lines.push HEADER5 + "Response" + NEWLINE
			example_lines.push "The following is an example of the response. Note: The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call." + NEWLINE
			example_lines.push get_json_response_pretext(method[:returnType]) + NEWLINE
			modeldump = get_json_model_method(method[:returnType], false, true, true)
			#modeldump = get_json_model_method(method[:returnType])
			example_lines.push "```http" + NEWLINE
			example_lines.push "HTTP/1.1 201 Created" + NEWLINE
			example_lines.push "Content-type: application/json" + NEWLINE
			example_lines.push "Content-length: #{modeldump.length.to_s}" + TWONEWLINES
			example_lines.push modeldump + NEWLINE
			example_lines.push "```" + NEWLINE

		when 'auto_get', 'auto_list'
			example_lines.push HEADER5 + "Request" + NEWLINE
			example_lines.push "The following is an example of the request." + NEWLINE
			example_lines.push get_json_request_pretext("get_#{@jsonHash[:name]}".downcase) + NEWLINE
			example_lines.push '```http' + NEWLINE
			httpSyntax = get_syntax('auto_get', top_one_restpath, nil, nil, SERVER)

			example_lines.push httpSyntax.join + "/#{pathAppend.to_s}".chomp('/') + NEWLINE
			example_lines.push "```" + NEWLINE

			example_lines.push HEADER5 + "Response" + NEWLINE
			example_lines.push "The following is an example of the response. Note: The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call." + NEWLINE
			if type == 'auto_list'
				modeldump = get_json_model_method(@jsonHash[:collectionOf], true)
				example_lines.push get_json_response_pretext(@jsonHash[:collectionOf], true) + NEWLINE
			else
				modeldump = get_json_model_method(@jsonHash[:name])
				example_lines.push get_json_response_pretext(@jsonHash[:name]) + NEWLINE
			end
			# todo : how do i handle the collections?

			example_lines.push "```http" + NEWLINE
			example_lines.push "HTTP/1.1 200 OK" + NEWLINE
			example_lines.push "Content-type: application/json" + NEWLINE
			example_lines.push "Content-length: #{modeldump.length.to_s}" + TWONEWLINES
			example_lines.push modeldump + NEWLINE
			example_lines.push "```" + NEWLINE

		when 'auto_patch'

			example_lines.push HEADER5 + "Request" + NEWLINE
			example_lines.push "The following is an example of the request." + NEWLINE
			example_lines.push get_json_request_pretext("update_#{@jsonHash[:name]}".downcase) + NEWLINE

			example_lines.push '```http' + NEWLINE
			httpSyntax = get_syntax('auto_patch', top_one_restpath, nil, nil, SERVER)
			example_lines.push httpSyntax.join("\n") + NEWLINE
			modeldump = get_json_model_method(@jsonHash[:name], false, false)
			example_lines.push "Content-type: application/json" + NEWLINE
			example_lines.push "Content-length: #{modeldump.length.to_s}" + TWONEWLINES
			example_lines.push modeldump + NEWLINE
			example_lines.push "```" + NEWLINE
			example_lines.push HEADER5 + "Response" + NEWLINE
			example_lines.push "The following is an example of the response. Note: The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call." + NEWLINE
			example_lines.push get_json_response_pretext(@jsonHash[:name]) + NEWLINE
			modeldump = get_json_model_method(@jsonHash[:name])
			example_lines.push "```http" + NEWLINE
			example_lines.push "HTTP/1.1 200 OK" + NEWLINE
			example_lines.push "Content-type: application/json" + NEWLINE
			example_lines.push "Content-length: #{modeldump.length.to_s}" + TWONEWLINES
			example_lines.push modeldump + NEWLINE
			example_lines.push "```" + NEWLINE

		when 'auto_delete'
			example_lines.push HEADER5 + "Request" + NEWLINE
			example_lines.push "The following is an example of the request." + NEWLINE
			example_lines.push get_json_request_pretext("delete_#{@jsonHash[:name]}".downcase) + NEWLINE
			example_lines.push '```http' + NEWLINE
			httpSyntax = get_syntax(method[:name], top_one_restpath, nil, nil, SERVER)
			example_lines.push httpSyntax.join("\n") + NEWLINE
			example_lines.push '```' + NEWLINE

			example_lines.push HEADER5 + "Response" + NEWLINE
			example_lines.push "The following is an example of the response. Note: The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call." + NEWLINE
			example_lines.push get_json_response_pretext(nil) + NEWLINE
			example_lines.push "```http" + NEWLINE
			example_lines.push "HTTP/1.1 204 No Content" + NEWLINE
			example_lines.push "```" + NEWLINE
		else
			example_lines.push "The following is an example of how to call this API." + NEWLINE
			example_lines.push HEADER5 + "Request" + NEWLINE
			example_lines.push "The following is an example of the request." + NEWLINE
			example_lines.push get_json_request_pretext("#{@jsonHash[:name].downcase}_#{method[:name]}".downcase) + NEWLINE
			example_lines.push '```http' + NEWLINE
			httpSyntax = get_syntax(method[:name], top_one_restpath, nil, nil, SERVER)
			example_lines.push httpSyntax.join("\n") + NEWLINE

			if !method[:isFunction] && method[:parameters].length > 0
				@logger.debug("Calling: #{method}")
				modeldump = get_json_model_params(method[:parameters])
				example_lines.push "Content-type: application/json" + NEWLINE
				example_lines.push "Content-length: #{modeldump.length.to_s}" + TWONEWLINES
				example_lines.push modeldump + NEWLINE
			# else
			# 	example_lines.push "Content-length: 0" + NEWLINE
			end
			example_lines.push '```' + TWONEWLINES

			example_lines.push HEADER5 + "Response" + NEWLINE
			example_lines.push "The following is an example of the response. "

			if method[:returnType] != nil && method[:returnType] != 'None'
				example_lines.push "Note: The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call." + NEWLINE
			else
				example_lines.push NEWLINE
			end

			if method[:isReturnTypeCollection]
				example_lines.push get_json_response_pretext(method[:returnType], true) + NEWLINE
			else
				example_lines.push get_json_response_pretext(method[:returnType]) + NEWLINE
			end
			example_lines.push "```http" + NEWLINE
			example_lines.push "HTTP/1.1 200 OK" + NEWLINE
			if method[:returnType] != nil && method[:returnType] != 'None'
				modeldump = get_json_model_method(method[:returnType], method[:isReturnTypeCollection])
				example_lines.push "Content-type: application/json" + NEWLINE
				example_lines.push "Content-length: #{modeldump.length.to_s}" + TWONEWLINES
				example_lines.push modeldump + NEWLINE
			# else
			# 	example_lines.push "Content-length: 0" + NEWLINE
			end
			example_lines.push "```" + NEWLINE
		end

		return example_lines
	end

	def self.top_restpath
		arr = @jsonHash[:restPath].select { |_, v| v }.keys.sort_by {|x| x.length}
		return arr[0..2]
	end

	def self.top_one_restpath
		arr = @jsonHash[:restPath].select { |_, v| v }.keys.sort_by {|x| x.length}
		return arr[0..0]
	end

	def self.get_syntax(methodName=nil, restpath=[], pathAppend='', method=nil, server = '')
		restpath = restpath.sort_by {|x| x.length}
		case methodName
		when 'auto_get', 'auto_list'
			arr = restpath.map {|a| "GET " + server + a.to_s + "/#{pathAppend.to_s}".chomp('/')}
		when 'auto_post'
			# have to append the collection name for post
			arr = restpath.map {|a| "POST " + server + a.to_s + "/#{pathAppend}".chomp('/')}
		when 'auto_delete'
			arr = restpath.map {|a| "DELETE " + server + a.to_s}
		when 'auto_put'
			arr = restpath.map {|a| "PUT " + server + a.to_s}
		when 'auto_patch'
			arr = restpath.map {|a| "PATCH " + server + a.to_s}
		else
			# identify the functional path
			if method && method[:isFunction] && method[:parameters].length > 0
				q = ''
				method[:parameters].each do |item|
					q= q + item[:name] + "=#{item[:name]}-value, "
				end
				q = "(" + q.chomp(', ') + ")"
				arr = restpath.map {|a| "POST " + server + a.to_s + "/#{methodName}#{q}" }

			else
				arr = restpath.map {|a| "POST " + server + a.to_s + "/#{methodName}"}
			end
		end
		return arr
	end

	# Write properties and methods to the final array.
	def self.push_property  (prop = {})

		# Add read-only and possible Enum values from the list.
		finalDesc = prop[:description]
		if prop[:dataType] == 'DateTimeOffset'
			finalDesc = finalDesc + TIMESTAMP_DESC
		end
		appendEnum = ''
		if (prop[:enumName] != nil) && (@enumHash.has_key? prop[:enumName])

			appendEnum = " Possible values are: `" + @enumHash[prop[:enumName]]["options"].keys.join('`, `') + "`."
			finalDesc = finalDesc + appendEnum
		end
		finalDesc = (prop[:isReadOnly] || prop[:isKey]) ? finalDesc  + ' Read-only.' : finalDesc
		finalDesc = prop[:isNullable] ? finalDesc + ' Nullable.' : finalDesc

		# If the type is of	an object, then provide markdown link.
		if SIMPLETYPES.include? prop[:dataType]
			dataTypePlusLink = prop[:dataType]
		else
			dataTypePlusLink = "[" + prop[:dataType] + "](" + prop[:dataType].downcase + ".md)"
			# if prop[:isCollection]
			# 	dataTypePlusLink = "[" + prop[:dataType] + "](" + prop[:dataType].chomp('[]').downcase + ".md)"
			# end
		end
		if prop[:isCollection]
			dataTypePlusLink = dataTypePlusLink + " collection"
		end

		@mdlines.push (PIPE + prop[:name] + PIPE + dataTypePlusLink + PIPE + finalDesc + PIPE ) + NEWLINE
	end

	# Write methods to the final array (in resource file).
	def self.push_method (method = {})
		# If the type is of	an object, then provide markdown link.
		if method[:returnType].to_s.empty?
			method[:returnType] = 'None'
		end

		if (SIMPLETYPES.include? method[:returnType]) || (method[:returnType] == 'None')
			dataTypePlusLink = method[:returnType]
		else
			dataTypePlusLink = "[" + method[:returnType] + "](" + method[:returnType].downcase + ".md)"
		end

		if method[:isReturnTypeCollection]
			dataTypePlusLink = dataTypePlusLink + " collection"
		end

		# Add links to method.
		#restfulTask = method[:name].start_with?('get') ? ('Get ' + method[:name][3..-1]) : method[:name].capitalize
		restfulTask = method[:name]
		methodPlusLink = "[" + restfulTask.strip.capitalize + "](../api/" + @jsonHash[:name].downcase + "_" + method[:name].downcase + ".md)"
		@mdlines.push (PIPE + methodPlusLink + PIPE + dataTypePlusLink + PIPE + method[:description] + PIPE) + NEWLINE
		create_method_mdfile method
	end

	# Create separate actions and functions file 
	def self.create_method_mdfile (method = {}, autoFilename=nil, pathAppend='')
		actionLines = []
		# Header and description

		if method[:displayName].empty?
			h1name = "#{@jsonHash[:name]}: #{method[:name]}"
		else
			h1name = "#{method[:displayName]}"
		end
		actionLines.push HEADER1 + h1name + TWONEWLINES

		actionLines.push "#{method[:description]}"  + NEWLINE

		actionLines.push PREREQ

		### HTTP request
		# Select only the keys (that contains the REST path) for which the value (display or not flag)
		# is set to true.
		#
		actionLines.push HEADER2 + "HTTP request" + NEWLINE
		actionLines.push '<!-- { "blockType": "ignored" } -->' + NEWLINE
		actionLines.push '```http' + NEWLINE
		
		httpSyntax = get_syntax(method[:name], top_restpath, pathAppend, method)
		actionLines.push httpSyntax.join("\n") + NEWLINE
		actionLines.push NEWLINE + '```' + NEWLINE

		#Query parameters
		if method[:name] == 'auto_get' || method[:name] == 'auto_list'
			#Handle Query Params:::
		end

		#Request headers
		actionLines.push HEADER2 + "Request headers" + NEWLINE
		actionLines.push HTTP_HEADER
		actionLines.push TABLE_2ND_LINE_2COL
		actionLines.push HTTP_HEADER_SAMPLE + NEWLINE
		actionLines.push NEWLINE

		#Request body
		actionLines.push HEADER2 + "Request body" + NEWLINE

		# Provide parameters:
		if method[:parameters] !=nil && method[:parameters].length > 0
			if method[:isFunction]
				actionLines.push "In the request URL, provide following query parameters with values." + TWONEWLINES
			else
				actionLines.push "In the request body, provide a JSON object with the following parameters." + TWONEWLINES
			end
			actionLines.push PARAM_HEADER + TABLE_2ND_LINE
			method[:parameters].each do |param|
				# Append optional and enum possible values (if applicable).
				finalPDesc = param[:isRequired] ? param[:description] : 'Optional. ' + param[:description]
				appendEnum = ''

				if (param[:enumName] != nil) && (@enumHash.has_key? param[:enumName])
					appendEnum = " " + " Possible values are: `" + @enumHash[param[:enumName]]["options"].keys.join('`, `') + "`."
					finalPDesc = finalPDesc + appendEnum
				end
				actionLines.push (PIPE + param[:name] + PIPE + param[:dataType] + PIPE + finalPDesc + PIPE) + NEWLINE
			end
		else
			case method[:name]
			when 'auto_post'
				actionLines.push "In the request body, supply a JSON representation of [#{method[:returnType]}](../resources/#{method[:returnType].downcase}.md) object." + NEWLINE
				actionLines.push NEWLINE
			when 'auto_delete'
				actionLines.push "Do not supply a request body for this method." + NEWLINE
				actionLines.push NEWLINE
			end
		end

		actionLines.push NEWLINE

		#Response body
		actionLines.push HEADER2 + "Response" + NEWLINE

		if !method[:returnType].nil?
			if SIMPLETYPES.include? method[:returnType]
				dataTypePlusLink = method[:returnType]
			else
				dataTypePlusLink = "[" + method[:returnType] + "](../resources/" + method[:returnType].downcase + ".md)"
			end
		else
			dataTypePlusLink = 'none'
		end

		if method[:returnType].nil? || method[:returnType] ==  'None'
			actionLines.push "If successful, this method returns `#{method[:httpSuccessCode]}, #{HTTP_CODES[method[:httpSuccessCode]]}` response code. It does not return anything in the response body."  + NEWLINE
		else
			trueReturn = dataTypePlusLink
			trueReturn = trueReturn + ' collection' if method[:isReturnTypeCollection]
			actionLines.push "If successful, this method returns `#{method[:httpSuccessCode]}, #{HTTP_CODES[method[:httpSuccessCode]]}` response code and #{trueReturn} object in the response body."  + NEWLINE
		end

		# Write example files
		# begin
		example_lines = []

		case method[:name]
		when 'auto_post'
			example_lines = gen_example("auto_post", method, pathAppend)
		when 'auto_delete'
			example_lines = gen_example("auto_delete", method)
		else
			example_lines = gen_example(method[:name], method)
		end

		actionLines.push NEWLINE

		example_lines.each do |line|
			actionLines.push line
		end

		actionLines.push NEWLINE + uuid_date + NEWLINE
		actionLines.push get_json_page_annotation(h1name)

		# Write the output file.
		if autoFilename
			fileName = autoFilename
		else
			fileName = "#{@jsonHash[:name].downcase}_#{method[:name].downcase}.md"
		end
		outfile = MARKDOWN_API_FOLDER + fileName

		file=File.new(outfile,'w')
		actionLines.each do |line|
			file.write line
		end
		@method_files_created = @method_files_created + 1
	end

	def self.create_get_method(pathAppend = nil, filenameOverride = nil)
		getMethodLines = []
		# Header and description
		realHeader = @jsonHash[:collectionOf] ? ('List ' + @jsonHash[:name]) : ('Get ' + @jsonHash[:name])
		getMethodLines.push HEADER1 + realHeader + TWONEWLINES

		if @jsonHash[:collectionOf]
			getMethodLines.push "Retrieve a list of #{@jsonHash[:collectionOf].downcase} objects."  + NEWLINE
		else
			getMethodLines.push "Retrieve the properties and relationships of #{@jsonHash[:name].downcase} object."  + NEWLINE
		end

		getMethodLines.push PREREQ
		# HTTP request
		getMethodLines.push HEADER2 + "HTTP request" + NEWLINE
		getMethodLines.push '<!-- { "blockType": "ignored" } -->' + NEWLINE

		getMethodLines.push '```http' + NEWLINE
		if @jsonHash[:collectionOf]
			httpSyntax = get_syntax('auto_list', top_restpath, pathAppend)
		else
			httpSyntax = get_syntax('auto_get', top_restpath)
		end

		getMethodLines.push httpSyntax.join("\n") + NEWLINE
		getMethodLines.push  '```' + NEWLINE

		#Query parameters 
		getMethodLines.push HEADER2 + "Optional query parameters" + NEWLINE
		getMethodLines.push "This method supports the [OData Query Parameters](http://graph.microsoft.io/docs/overview/query_parameters) to help customize the response." + NEWLINE

		# if @jsonHash[:collectionOf]
		# 	getMethodLines.push QRY_HEADER + NEWLINE
		# 	getMethodLines.push QRY_2nd_LINE + NEWLINE

		# 	# countable, expandable, selectable, filterable, skipSupported, topSupported, sortable = true, true, true, true, true, true, true
		# 	# annotationTarget = @annotations[@jsonHash[:collectionOf].downcase]
			
		# 	# if annotationTarget
		# 	# 	countable = annotationTarget["countrestrictions/countable"].nil? ? true : annotationTarget["countrestrictions/countable"]
		# 	# 	expandable = annotationTarget["expandrestrictions/expandable"].nil? ? true : annotationTarget["expandrestrictions/expandable"]
		# 	# 	selectable = annotationTarget["selectrestrictions/selectable"].nil? ? true : annotationTarget["selectrestrictions/selectable"]
		# 	# 	filterable = annotationTarget["filterrestrictions/filterable"].nil? ? true : annotationTarget["filterrestrictions/filterable"]
		# 	# 	skipSupported = annotationTarget["skipsupported"].nil? ? true : annotationTarget["skipsupported"]
		# 	# 	topSupported = annotationTarget["topsupported"].nil? ? true : annotationTarget["topsupported"]
		# 	# 	sortable = annotationTarget["sortrestrictions/sortable"].nil? ? true : annotationTarget["sortrestrictions/sortable"]
		# 	# end
		# 	# if countable
		# 	# 	getMethodLines.push QRY_COUNT +  NEWLINE
		# 	# end
		# 	# if expandable
		# 	# 	getMethodLines.push QRY_EXPAND + "See relationships table of [#{@jsonHash[:collectionOf]}](../resources/#{@jsonHash[:collectionOf].downcase}.md) for supported names. |" + NEWLINE
		# 	# end
		# 	# if filterable
		# 	# 	getMethodLines.push QRY_FILTER + NEWLINE
		# 	# end
		# 	# if sortable
		# 	# 	getMethodLines.push QRY_ORDERBY + NEWLINE
		# 	# end
		# 	# if selectable
		# 	# 	getMethodLines.push QRY_SELECT + NEWLINE
		# 	# end
		# 	# if skipSupported
		# 	# 	getMethodLines.push QRY_SKIP + NEWLINE
		# 	# 	getMethodLines.push QRY_SKIPTOKEN + NEWLINE
		# 	# end
		# 	# if topSupported
		# 	# 	getMethodLines.push QRY_TOP + NEWLINE
		# 	# end
		# else
		# 	countable, expandable, selectable  = true, true, true
		# 	annotationTarget = @annotations[@jsonHash[:name].downcase]

		# 	if annotationTarget
		# 		countable = annotationTarget["countrestrictions/countable"].nil? ? true : annotationTarget["countrestrictions/countable"]
		# 		expandable = annotationTarget["expandrestrictions/expandable"].nil? ? true : annotationTarget["expandrestrictions/expandable"]
		# 		selectable = annotationTarget["selectrestrictions/selectable"].nil? ? true : annotationTarget["selectrestrictions/selectable"]
		# 	end
		# 	if annotationTarget && !countable && !expandable && !selectable
		# 	else
		# 		getMethodLines.push QRY_HEADER + NEWLINE
		# 		getMethodLines.push QRY_2nd_LINE + NEWLINE
		# 		if countable
		# 			getMethodLines.push QRY_COUNT + NEWLINE
		# 		end
		# 		if expandable
		# 			getMethodLines.push QRY_EXPAND + "See relationships table of [#{@jsonHash[:name]}](../resources/#{@jsonHash[:name].downcase}.md) object for supported names. |" + NEWLINE
		# 		end
		# 		if selectable
		# 			getMethodLines.push QRY_SELECT + NEWLINE
		# 		end
		# 	end
		# end

		#Request headers
		getMethodLines.push NEWLINE + HEADER2 + "Request headers" + NEWLINE
		getMethodLines.push "| Name      |Description|" + NEWLINE
		getMethodLines.push "|:----------|:----------|" + NEWLINE
		getMethodLines.push HTTP_HEADER_SAMPLE + NEWLINE
		getMethodLines.push NEWLINE

		#Request body
		getMethodLines.push HEADER2 + "Request body" + NEWLINE
		getMethodLines.push "Do not supply a request body for this method." + NEWLINE

		#Response body
		getMethodLines.push HEADER2 + "Response" + NEWLINE
		if @jsonHash[:collectionOf]
			getMethodLines.push "If successful, this method returns a `200 OK` response code and collection of [#{@jsonHash[:collectionOf]}](../resources/#{@jsonHash[:collectionOf].downcase}.md) objects in the response body."  + NEWLINE
		else
			getMethodLines.push "If successful, this method returns a `200 OK` response code and [#{@jsonHash[:name]}](../resources/#{@jsonHash[:name].downcase}.md) object in the response body."  + NEWLINE
		end

		#Example
		if @jsonHash[:collectionOf]
			example_lines = gen_example("auto_list", nil, pathAppend)
		else
			example_lines = gen_example("auto_get")
		end
		example_lines.each do |line|
			getMethodLines.push line
		end

		getMethodLines.push NEWLINE + uuid_date + NEWLINE
		# Write the output file.
		getMethodLines.push get_json_page_annotation(realHeader)

		fileName = @jsonHash[:collectionOf] ? "#{@jsonHash[:collectionOf].downcase}_list.md" : "#{@jsonHash[:name].downcase}_get.md"
		if filenameOverride
			outfile = MARKDOWN_API_FOLDER + filenameOverride
		else
			outfile = MARKDOWN_API_FOLDER + fileName
		end
		# if File.exists?(outfile)
		# 	puts "*-----> List file #{outfile} already exists."
		# end
		file=File.new(outfile,'w')
		getMethodLines.each do |line|
			file.write line
		end
		@get_list_files_created = @get_list_files_created + 1
	end

	def self.create_patch_method (propreties=[])
		patchMethodLines = []

		# Header and description

		if @jsonHash[:updateDescription].empty?
			h1name = "Update #{@jsonHash[:name].downcase}"
		else
			h1name = "#{@jsonHash[:updateDescription]}"
		end

		patchMethodLines.push HEADER1 + h1name + TWONEWLINES

		if @jsonHash[:updateDescription].empty?
			patchMethodLines.push "Update the properties of #{@jsonHash[:name].downcase} object."  + NEWLINE
		else
			patchMethodLines.push "#{@jsonHash[:updateDescription]}"  + NEWLINE
		end

		patchMethodLines.push PREREQ
		# HTTP request
		patchMethodLines.push HEADER2 + "HTTP request" + NEWLINE
		patchMethodLines.push '<!-- { "blockType": "ignored" } -->' + NEWLINE
		patchMethodLines.push '```http' + NEWLINE
		# httpPatchArray = @jsonHash[:restPath].map {|a| "PATCH " + a.to_s}
		# patchMethodLines.push httpPatchArray.join("\n") + NEWLINE

		httpSyntax = get_syntax('auto_patch', top_restpath)
		patchMethodLines.push httpSyntax.join("\n") + NEWLINE
		patchMethodLines.push  '```' + NEWLINE

		#Request headers
		patchMethodLines.push HEADER2 + "Optional request headers" + NEWLINE
		patchMethodLines.push "| Name       | Description|" + NEWLINE
		patchMethodLines.push "|:-----------|:-----------|" + NEWLINE
		patchMethodLines.push HTTP_HEADER_SAMPLE  + NEWLINE
		patchMethodLines.push NEWLINE

		#Request body
		patchMethodLines.push HEADER2 + "Request body" + NEWLINE
		patchMethodLines.push "In the request body, supply the values for relevant fields that should be updated. Existing properties that are not included in the request body will maintain their previous values or be recalculated based on changes to other property values. For best performance you shouldn't include existing values that haven't changed." + NEWLINE
		patchMethodLines.push NEWLINE

		patchMethodLines.push PROPERTY_HEADER + TABLE_2ND_LINE 
		propreties.each do |prop|
			if !prop[:isReadOnly]
		   		finalDesc = prop[:description]
				appendEnum = ''
				if (prop[:enumName] != nil) && (@enumHash.has_key? prop[:enumName])
					appendEnum = " Possible values are: `" + @enumHash[prop[:enumName]]["options"].keys.join('`, `') + "`."
					finalDesc = finalDesc + appendEnum
				end
				patchMethodLines.push (PIPE + prop[:name] + PIPE + prop[:dataType]  + PIPE + finalDesc + PIPE ) + NEWLINE
			end
		end
		patchMethodLines.push NEWLINE

		#Response body
		patchMethodLines.push HEADER2 + "Response" + NEWLINE
		patchMethodLines.push "If successful, this method returns a `200 OK` response code and updated [#{@jsonHash[:name]}](../resources/#{@jsonHash[:name].downcase}.md) object in the response body."  + NEWLINE

		#Example
		example_lines = gen_example("auto_patch")
		example_lines.each do |line|
			patchMethodLines.push line
		end
		patchMethodLines.push NEWLINE + uuid_date + NEWLINE
		patchMethodLines.push get_json_page_annotation(h1name)

		# Write the output file.
		fileName = "#{@jsonHash[:name].downcase}_update.md"
		outfile = MARKDOWN_API_FOLDER + fileName
		file=File.new(outfile,'w')
		patchMethodLines.each do |line|
			file.write line
		end
		@patch_files_created = @patch_files_created + 1

	end

	# Conversion to specification
	def self.convert_to_spec (item=nil)
		@mdlines = []
		isPost = nil
		@jsonHash = JSON.parse(item, {:symbolize_names => true})

		if @jsonHash[:isEntitySet]
			@ientityset = @ientityset + 1
			@serviceroot.push @jsonHash
			return
		end

		# Obtain the resource name.
		@resource = @jsonHash[:name]
		puts "--> #{@resource}"

		propreties = @jsonHash[:properties]
		if propreties && propreties.length > 1
			propreties = propreties.sort_by { |v| v[:name] }
		end

		methods = @jsonHash[:methods]
		if methods != nil && methods.length > 1
			methods = methods.sort_by { |v| v[:name] }
		end

		# Header and description
		@mdlines.push HEADER1 + @jsonHash[:name] + ' resource type' + TWONEWLINES
		@mdlines.push @jsonHash[:description] + TWONEWLINES

		# Determine if there is/are: relations, properties and methods.
		isRelation, isProperty, isMethod, patchable = false, false, false, false

		propreties.each do |prop|
			if !prop[:isRelationship]
			   isProperty = true
			   if !prop[:isReadOnly] && @jsonHash[:allowPatch]
			   	  patchable = true
			   end
			end
			if prop[:isRelationship]
			   isRelation = true
			   if prop[:isCollection] && prop[:allowPostToCollection]
			   		isPost = true
			   end
			end
		end

		if methods
			isMethod = true
		end

		# Add method table.
		if !@jsonHash[:isComplexType]
			@mdlines.push NEWLINE + HEADER2 + 'Methods' + NEWLINE

			if isMethod || isProperty || isPost || @jsonHash[:allowDelete]
				@mdlines.push NEWLINE + TASKS_HEADER + TABLE_2ND_LINE
			end
			if !@jsonHash[:isComplexType]
				if @jsonHash[:collectionOf]
					returnLink = "[" + @jsonHash[:collectionOf] + "](" + @jsonHash[:collectionOf].downcase + ".md)"
					@mdlines.push "|[List](../api/#{@jsonHash[:collectionOf].downcase}_list.md) | #{returnLink} collection |Get #{uncapitalize @jsonHash[:collectionOf]} object collection. |" + NEWLINE
				else
					if isProperty
						returnLink = "[" + @jsonHash[:name] + "](" + @jsonHash[:name].downcase + ".md)"
						@mdlines.push "| [Get #{@jsonHash[:name]}](../api/#{@jsonHash[:name].downcase}_get.md) | #{returnLink} | Read properties and relationships of #{uncapitalize @jsonHash[:name]} object. |" + NEWLINE
					end
				end
				create_get_method
			end

			# Run through all the collection relationships and add a task for posting
			# to the right resouce to create the object.
			# Based on the data type, the name of the API varies.
			if isPost
				propreties.each do |prop|
					if prop[:isRelationship] && prop[:isCollection] && prop[:allowPostToCollection]
						if SIMPLETYPES.include?(prop[:dataType]) ||
								POST_NAME_MAPPING.include?(prop[:dataType].downcase)
							useName = prop[:name].chomp('s')
							postName = "Create " + useName
						else
							useName = prop[:dataType]
							postName = "Create " + useName
						end
						filename = "#{@jsonHash[:name].downcase}_post_#{prop[:name].downcase}.md"
						postLink = "../api/#{@jsonHash[:name].downcase}_post_#{prop[:name].downcase}.md"
						if SIMPLETYPES.include? prop[:dataType]
							returnLink = prop[:dataType]
						else
							returnLink = "[" + prop[:dataType] + "](" + prop[:dataType].downcase + ".md)"
						end
						@mdlines.push "| [#{postName}](#{postLink}) | #{returnLink} | Create a new #{useName} by posting to the #{prop[:name]} collection. |" + NEWLINE
						if File.exists?("#{MARKDOWN_API_FOLDER}/filename")
							puts "POST create file already exists!"
						else
							mtd = deep_copy(@struct[:method])

							mtd[:name] = 'auto_post'
							mtd[:displayName] = postName
							mtd[:returnType] = prop[:dataType]
							createDescription = get_create_description(mtd[:returnType])
							if createDescription.empty?
								mtd[:description] = "Use this API to create a new #{useName}."
							else
								mtd[:description] = createDescription
							end

							mtd[:parameters] = nil
							mtd[:httpSuccessCode] = '201'
							create_method_mdfile(mtd, "#{@jsonHash[:name].downcase}_post_#{prop[:name].downcase}.md", prop[:name])
						end

						# Add List method.
						if !SIMPLETYPES.include? prop[:dataType]
							#filename = "#{prop[:dataType].downcase}_list.md"

							filename = "#{@jsonHash[:name]}_list_#{prop[:name]}.md".downcase
							listLink = "../api/#{filename}"

							# puts "$----> #{filename} #{@jsonHash[:name]},, #{prop[:name]}"
							@mdlines.push "| [List #{prop[:name]}](#{listLink}) | #{returnLink} collection | Get a #{useName} object collection. |" + NEWLINE
							saveJsonHash = deep_copy @jsonHash
							@jsonHash[:name] = prop[:name]
							@jsonHash[:collectionOf] = prop[:dataType]
							create_get_method(prop[:name], filename)
							@jsonHash = deep_copy saveJsonHash
							@list_from_rel = @list_from_rel + 1
						end

					end
				end
			end

			if patchable
				returnLink = "[" + @jsonHash[:name] + "](" + @jsonHash[:name].downcase + ".md)"
				@mdlines.push "| [Update](../api/#{@jsonHash[:name].downcase}_update.md) | #{returnLink} | Update #{@jsonHash[:name]} object. |" + NEWLINE
				create_patch_method propreties
				# mtd = deep_copy(@struct[:method])
				# mtd[:name] = 'auto_patch'
				# mtd[:displayName] = 'Update'
				# mtd[:returnType] = @jsonHash[:name]
				# mtd[:description] = "Update @jsonHash[:name]."
				# mtd[:parameters] = nil
				# mtd[:httpSuccessCode] = '200'
				# create_method_mdfile(mtd, "#{@jsonHash[:name].downcase}_update.md")
			end

			if @jsonHash[:allowDelete]
				@mdlines.push "| [Delete](../api/#{@jsonHash[:name].downcase}_delete.md) | None | Delete #{@jsonHash[:name]} object. |" + NEWLINE
				mtd = deep_copy(@struct[:method])
				mtd[:displayName] = "Delete #{@jsonHash[:name]}"
				mtd[:name] = 'auto_delete'

				if @jsonHash[:deleteDescription].empty?
					mtd[:description] = mtd[:description] = "Delete #{@jsonHash[:name]}."
				else
					mtd[:description] = @jsonHash[:deleteDescription]
				end
				mtd[:httpSuccessCode] = '204'
				mtd[:parameters] = nil
				create_method_mdfile(mtd, "#{@jsonHash[:name].downcase}_delete.md")
			end

			if isMethod
				methods.each do |mtd|
					push_method mtd
				end
			end

			if !isProperty && !isMethod && !isPost
				@mdlines.push "None"  + TWONEWLINES
			end

			if !@jsonHash[:methodNotes].empty?
				@mdlines.push NEWLINE + "**Note:** #{@jsonHash[:methodNotes]}" + NEWLINE
			end
		end

		# Add property table.
		@mdlines.push NEWLINE

		@mdlines.push HEADER2 + 'Properties' + NEWLINE
		if isProperty
			@mdlines.push PROPERTY_HEADER + TABLE_2ND_LINE
			propreties.each do |prop|
				if !prop[:isRelationship]
				   push_property prop
				end
			end
			if !@jsonHash[:propertyNotes].empty?
				@mdlines.push NEWLINE + "**Note:** #{@jsonHash[:propertyNotes]}" + NEWLINE
			end
		else
			@mdlines.push "None"  + NEWLINE
		end

		# Add Relationship table.
		if !@jsonHash[:isComplexType]
			@mdlines.push NEWLINE
			@mdlines.push HEADER2 + 'Relationships' + NEWLINE
			if isRelation
				@mdlines.push RELATIONSHIP_HEADER + TABLE_2ND_LINE
				propreties.each do |prop|
					if prop[:isRelationship]
						push_property prop
					end
				end
				if !@jsonHash[:relationshipNotes].empty?
					@mdlines.push NEWLINE + "**Note:** #{@jsonHash[:relationshipNotes]}" + NEWLINE
				end
			else
				@mdlines.push "None"  + TWONEWLINES
			end
		end

		# Header and description
		if !@jsonHash[:isEntitySet] && isProperty
			@mdlines.push NEWLINE
			@mdlines.push HEADER2 + 'JSON representation' + TWONEWLINES
			@mdlines.push 'The following is a JSON representation of the resource.' + TWONEWLINES

			@mdlines.push get_json_model_pretext(@jsonHash[:name],propreties) + TWONEWLINES

			@mdlines.push "```json" + NEWLINE
			#@mdlines.push get_json_model(propreties) + TWONEWLINES
			jsonpretty = pretty_json(get_json_model(propreties))
			@mdlines.push jsonpretty + TWONEWLINES

			@mdlines.push "```" + NEWLINE
		end

		@mdlines.push NEWLINE + uuid_date + NEWLINE

		# do we need this for tool check?
		@mdlines.push get_json_page_annotation(@jsonHash[:name] + " resource")

		# Write the output file.
		if @jsonHash[:isEntitySet]
			outfile = MARKDOWN_RESOURCE_FOLDER + @resource.downcase + '_collection.md'
		else
			outfile = MARKDOWN_RESOURCE_FOLDER + @resource.downcase + '.md'
		end
		file=File.new(outfile,'w')
		@mdlines.each do |line|
			file.write line
		end
		@resources_files_created = @resources_files_created + 1

	end

	def self.create_service_root
		service_lines = []

		service_lines.push HEADER1 + 'Service root' + TWONEWLINES
		service_lines.push NEWLINE + HEADER2 + 'Methods' + NEWLINE
		service_lines.push NEWLINE + TASKS_HEADER + TABLE_2ND_LINE

		@serviceroot.each do |item|
			if item[:collectionOf]
				useName = item[:collectionOf]
				postName = "Create " + useName
				filename = "#{item[:collectionOf].downcase}_post_#{item[:name].downcase}.md"
				postLink = "../api/#{item[:collectionOf].downcase}_post_#{item[:name].downcase}.md"
				returnLink = "[" + item[:collectionOf] + "](" + item[:collectionOf].downcase + ".md)"
				service_lines.push "| [#{postName}](#{postLink}) | #{returnLink} | Create a new #{useName} by posting to the #{item[:name] } collection. |" + NEWLINE
				if File.exists?("#{MARKDOWN_API_FOLDER}/filename")
					puts "EntitySet POST create file already exists!"
				else
					mtd = deep_copy(@struct[:method])
					mtd[:name] = 'auto_post'
					mtd[:displayName] = postName
					mtd[:returnType] = item[:collectionOf]
					createDescription = get_create_description(item[:collectionOf])
					if createDescription.empty?
						mtd[:description] = "Use this API to create a new #{useName}."
					else
						mtd[:description] = createDescription
					end
					mtd[:parameters] = nil
					mtd[:httpSuccessCode] = '201'
					@jsonHash = item
					create_method_mdfile(mtd, filename)
				end
			end
			if item[:collectionOf]
				returnLink = "[" + item[:collectionOf] + "](" + item[:collectionOf].downcase + ".md)"
				service_lines.push "|[List #{item[:collectionOf]}](../api/#{item[:collectionOf].downcase}_list.md) | #{returnLink} collection |Get #{uncapitalize item[:collectionOf]} object collection. |" + NEWLINE
				@jsonHash = item
				create_get_method
			end
		end

		service_lines.push NEWLINE + uuid_date + NEWLINE
		service_lines.push get_json_page_annotation("Service root")
		outfile = MARKDOWN_RESOURCE_FOLDER + 'service_root.md'
		file=File.new(outfile,'w')
		service_lines.each do |line|
			file.write line
		end

	end

	#####
	# Main loop. Process each JSON files.
	#
	###
	processed_files = 0
	Dir.foreach(JSON_SOURCE_FOLDER) do |item|
		next if item == '.' or item == '..'
		fullpath = JSON_SOURCE_FOLDER + item.downcase

		if File.file?(fullpath)
			convert_to_spec File.read(fullpath, :encoding => 'UTF-8')
			processed_files = processed_files + 1
		end
	end
	create_service_root

	puts ""
	puts "*** OK. Processed #{processed_files} input files. Check #{File.expand_path(LOG_FOLDER)} folder for results. ***"
	puts "*** @resources_files_created #{@resources_files_created}"
	puts "*** @get_list_files_created #{@get_list_files_created} "
	puts "*** @patch_files_created #{@patch_files_created}"
	puts "*** @method_files_created #{@method_files_created}"
	puts "*** @list_from_relationships #{@list_from_rel}"
	puts "*** @ientityset #{@ientityset}"
end