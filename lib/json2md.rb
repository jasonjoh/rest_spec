###
# This program reads the JSON specification files and creates the Markdown files
# (minus the examples).
# Location: https://github.com/sumurthy/md_apispec
###
require 'pathname'
require 'logger'
require 'json'
require 'securerandom'
require 'optparse'
require_relative 'telemetry'

module SpecMaker
  $options = {
    version: 'v1.0',
    author: '',
    product: ''
  }

  OptionParser.new do |parser|
    parser.on('-v', '--version APIVERSION',
              'Specify API version to process. Defaults to v1.0') do |v|
      $options[:version] = v
    end

    parser.on('-a', '--author GITHUB-ALIAS',
              'Specify GitHub alias of owner of new documentation. Defaults to empty string.') do |a|
      $options[:author] = a
    end

    parser.on('-p', '--product PRODUCT',
              'Specify ms.prod value for new documentation. Defaults to empty string.') do |p|
      $options[:product] = p
    end

    parser.on('-h', '--help', 'Prints this help.') do
      puts(parser)
      exit
    end
  end.parse!

  Telemetry.log_json_to_markdown $options

  require_relative 'utils_j2m'

  def self.gen_example(type = nil, method = {}, path_append = nil)
    example_lines = []
    example_lines.push HEADER2 + 'Examples' + TWONEWLINES
    case type
    when 'auto_post'
      example_lines.push HEADER3 + 'Request' + TWONEWLINES
      example_lines.push 'The following is an example of the request.' + NEWLINE
      example_lines.push get_json_request_pretext("create_#{method[:returnType]}_from_#{@json_hash[:name]}".downcase) + TWONEWLINES
      example_lines.push '```http' + NEWLINE
      http_syntax = get_syntax('auto_post', top_one_rest_path, path_append, nil, SERVER)
      example_lines.push http_syntax.join(NEWLINE) + NEWLINE
      modeldump = get_json_model_method(method[:returnType], false, false, true)
      example_lines.push 'Content-type: application/json' + TWONEWLINES
      example_lines.push modeldump + NEWLINE
      example_lines.push '```' + TWONEWLINES

      example_lines.push HEADER3 + 'Response' + TWONEWLINES
      example_lines.push 'The following is an example of the response.' + TWONEWLINES
      example_lines.push ALERT_NOTE + 'The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call.' + TWONEWLINES
      example_lines.push get_json_response_pretext(method[:returnType]) + TWONEWLINES
      modeldump = get_json_model_method(method[:returnType], false, true, true)
      # modeldump = get_json_model_method(method[:returnType])
      example_lines.push '```http' + NEWLINE
      example_lines.push 'HTTP/1.1 201 Created' + NEWLINE
      example_lines.push 'Content-type: application/json' + TWONEWLINES
      example_lines.push modeldump + NEWLINE
      # rubocop:disable Style/IdenticalConditionalBranches
      example_lines.push '```' + NEWLINE
      # rubocop:enable Style/IdenticalConditionalBranches

    when 'auto_get', 'auto_list'
      example_lines.push HEADER3 + 'Request' + TWONEWLINES
      example_lines.push 'The following is an example of the request.' + NEWLINE
      example_lines.push get_json_request_pretext("get_#{@json_hash[:name]}".downcase) + TWONEWLINES
      example_lines.push '```http' + NEWLINE
      http_syntax = get_syntax('auto_get', top_one_rest_path, nil, nil, SERVER)

      example_lines.push http_syntax.join + "/#{path_append}".chomp('/') + NEWLINE
      example_lines.push '```' + TWONEWLINES

      example_lines.push HEADER3 + 'Response' + TWONEWLINES
      example_lines.push 'The following is an example of the response.' + TWONEWLINES
      example_lines.push ALERT_NOTE + 'The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call.' + TWONEWLINES
      if type == 'auto_list'
        modeldump = get_json_model_method(@json_hash[:collectionOf], true)
        example_lines.push get_json_response_pretext(@json_hash[:collectionOf], true) + TWONEWLINES
      else
        modeldump = get_json_model_method(@json_hash[:name])
        example_lines.push get_json_response_pretext(@json_hash[:name]) + TWONEWLINES
      end
      # TODO: how do i handle the collections?

      example_lines.push '```http' + NEWLINE
      example_lines.push 'HTTP/1.1 200 OK' + NEWLINE
      example_lines.push 'Content-type: application/json' + TWONEWLINES
      example_lines.push modeldump + NEWLINE
      # rubocop:disable Style/IdenticalConditionalBranches
      example_lines.push '```' + NEWLINE
      # rubocop:enable Style/IdenticalConditionalBranches

    when 'auto_patch'

      example_lines.push HEADER3 + 'Request' + TWONEWLINES
      example_lines.push 'The following is an example of the request.' + NEWLINE
      example_lines.push get_json_request_pretext("update_#{@json_hash[:name]}".downcase) + TWONEWLINES

      example_lines.push '```http' + NEWLINE
      http_syntax = get_syntax('auto_patch', top_one_rest_path, nil, nil, SERVER)
      example_lines.push http_syntax.join(NEWLINE) + NEWLINE
      modeldump = get_json_model_method(@json_hash[:name], false, false)
      example_lines.push 'Content-type: application/json' + TWONEWLINES
      example_lines.push modeldump + NEWLINE
      example_lines.push '```' + TWONEWLINES

      example_lines.push HEADER3 + 'Response' + TWONEWLINES
      example_lines.push 'The following is an example of the response.' + TWONEWLINES
      example_lines.push ALERT_NOTE + 'The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call.' + TWONEWLINES
      example_lines.push get_json_response_pretext(@json_hash[:name]) + TWONEWLINES
      modeldump = get_json_model_method(@json_hash[:name])
      example_lines.push '```http' + NEWLINE
      example_lines.push 'HTTP/1.1 200 OK' + NEWLINE
      example_lines.push 'Content-type: application/json' + TWONEWLINES
      example_lines.push modeldump + NEWLINE
      # rubocop:disable Style/IdenticalConditionalBranches
      example_lines.push '```' + NEWLINE
      # rubocop:enable Style/IdenticalConditionalBranches

    when 'auto_delete'
      example_lines.push HEADER3 + 'Request' + TWONEWLINES
      example_lines.push 'The following is an example of the request.' + NEWLINE
      example_lines.push get_json_request_pretext("delete_#{@json_hash[:name]}".downcase) + TWONEWLINES
      example_lines.push '```http' + NEWLINE
      http_syntax = get_syntax(method[:name], top_one_rest_path, nil, nil, SERVER)
      example_lines.push http_syntax.join(NEWLINE) + NEWLINE
      example_lines.push '```' + TWONEWLINES

      example_lines.push HEADER3 + 'Response' + TWONEWLINES
      example_lines.push 'The following is an example of the response.' + TWONEWLINES
      example_lines.push get_json_response_pretext(nil) + TWONEWLINES
      example_lines.push '```http' + NEWLINE
      example_lines.push 'HTTP/1.1 204 No Content' + NEWLINE
      # rubocop:disable Style/IdenticalConditionalBranches
      example_lines.push '```' + NEWLINE
      # rubocop:enable Style/IdenticalConditionalBranches
    else
      example_lines.push 'The following is an example of how to call this API.' + TWONEWLINES
      example_lines.push HEADER3 + 'Request' + TWONEWLINES
      example_lines.push 'The following is an example of the request.' + NEWLINE
      example_lines.push get_json_request_pretext("#{@json_hash[:name].downcase}_#{method[:name]}".downcase) + TWONEWLINES
      example_lines.push '```http' + NEWLINE
      http_syntax = get_syntax(method[:name], top_one_rest_path, nil, nil, SERVER)
      example_lines.push http_syntax.join(NEWLINE) + NEWLINE

      if !method[:isFunction] && !method[:parameters].empty?
        @logger.debug("Calling: #{method}")
        modeldump = get_json_model_params(method[:parameters])
        example_lines.push 'Content-type: application/json' + TWONEWLINES
        example_lines.push modeldump + NEWLINE
      end
      example_lines.push '```' + TWONEWLINES

      example_lines.push HEADER3 + 'Response' + TWONEWLINES
      example_lines.push 'The following is an example of the response.'

      if !method[:returnType].nil? && method[:returnType] != 'None'
        example_lines.push TWONEWLINES + ALERT_NOTE + 'The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call.' + TWONEWLINES
      else
        example_lines.push NEWLINE
      end

      if method[:isReturnTypeCollection]
        example_lines.push get_json_response_pretext(method[:returnType], true) + TWONEWLINES
      else
        example_lines.push get_json_response_pretext(method[:returnType]) + TWONEWLINES
      end
      example_lines.push '```http' + NEWLINE
      example_lines.push 'HTTP/1.1 200 OK' + NEWLINE
      if !method[:returnType].nil? && method[:returnType] != 'None'
        modeldump = get_json_model_method(method[:returnType], method[:isReturnTypeCollection])
        example_lines.push 'Content-type: application/json' + NEWLINE
        example_lines.push modeldump + NEWLINE
      end
      # rubocop:disable Style/IdenticalConditionalBranches
      example_lines.push '```' + NEWLINE
      # rubocop:enable Style/IdenticalConditionalBranches
    end

    example_lines
  end

  def self.top_rest_path
    arr = @json_hash[:restPath].select { |_, v| v }.keys.sort_by(&:length)
    arr[0..2]
  end

  def self.top_one_rest_path
    arr = @json_hash[:restPath].select { |_, v| v }.keys.sort_by(&:length)
    arr[0..0]
  end

  def self.get_syntax(method_name = nil, rest_path = [], path_append = '', method = nil, server = '')
    rest_path = rest_path.sort_by(&:length)
    case method_name
    when 'auto_get', 'auto_list'
      arr = rest_path.map { |a| 'GET ' + server + a.to_s + "/#{path_append}".chomp('/') }
    when 'auto_post'
      # have to append the collection name for post
      arr = rest_path.map { |a| 'POST ' + server + a.to_s + "/#{path_append}".chomp('/') }
    when 'auto_delete'
      arr = rest_path.map { |a| 'DELETE ' + server + a.to_s }
    when 'auto_put'
      arr = rest_path.map { |a| 'PUT ' + server + a.to_s }
    when 'auto_patch'
      arr = rest_path.map { |a| 'PATCH ' + server + a.to_s }
    else
      # identify the HTTP method
      # Per https://msdn.microsoft.com/en-us/library/hh537061.aspx
      # Functions are GET, not POST
      http_method = method && method[:isFunction] ? 'GET ' : 'POST '

      # identify the functional path
      if method && method[:isFunction] && !method[:parameters].empty?
        q = ''
        method[:parameters].each do |item|
          q = q + item[:name] + "=#{item[:name]}-value, "
        end
        q = '(' + q.chomp(', ') + ')'
        arr = rest_path.map { |a| http_method + server + a.to_s + "/#{method_name}#{q}" }

      else
        arr = rest_path.map { |a| http_method + server + a.to_s + "/#{method_name}" }
      end
    end
    arr.empty? ? ['JSON2MD ERROR: COULD NOT DETERMINE API PATH'] : arr
  end

  # Write properties and methods to the final array.
  def self.push_property(prop = {})
    # Add read-only and possible Enum values from the list.
    final_desc = prop[:description]
    final_desc += TIMESTAMP_DESC if prop[:dataType] == 'DateTimeOffset'

    if !prop[:enumName].nil? && @enum_hash.key?(prop[:enumName])

      append_enum = ' Possible values are: `' + @enum_hash[prop[:enumName]]['options'].keys.join('`, `') + '`.'
      final_desc += append_enum
    end
    final_desc += ' Read-only.' if prop[:isReadOnly] || prop[:isKey]
    final_desc += ' Nullable.' if prop[:isNullable]

    # If the type is of an object, then provide markdown link.
    data_type_plus_link = if SIMPLETYPES.include? prop[:dataType]
                            prop[:dataType]
                          else
                            '[' + prop[:dataType] + '](' + sanitize_file_name(prop[:dataType].downcase) + '.md)'
                          end

    data_type_plus_link += ' collection' if prop[:isCollection]

    @mdlines.push PIPE + prop[:name] + PIPE + data_type_plus_link + PIPE + final_desc + PIPE + NEWLINE
  end

  # Write methods to the final array (in resource file).
  def self.push_method(method = {})
    # If the type is of an object, then provide markdown link.
    method[:returnType] = 'None' if method[:returnType].to_s.empty?

    data_type_plus_link = if SIMPLETYPES.include?(method[:returnType]) || method[:returnType] == 'None'
                            method[:returnType]
                          else
                            '[' + method[:returnType] + '](' + sanitize_file_name(method[:returnType].downcase) + '.md)'
                          end

    data_type_plus_link += ' collection' if method[:isReturnTypeCollection]

    # Add links to method.
    # restful_task = method[:name].start_with?('get') ? ('Get ' + method[:name][3..-1]) : method[:name].capitalize
    restful_task = method[:name]
    method_plus_link = '[' + restful_task.strip.capitalize + '](../api/' + sanitize_file_name(@json_hash[:name].downcase) + '-' + method[:name].downcase + '.md)'
    @mdlines.push PIPE + method_plus_link + PIPE + data_type_plus_link + PIPE + method[:description] + PIPE + NEWLINE
    create_method_mdfile method
  end

  def self.get_yaml_header(title = '', description = '')
    header_lines = []
    header_lines.push '---' + NEWLINE
    header_lines.push "title: \"#{title}\"" + NEWLINE
    header_lines.push "description: \"#{description}\"" + NEWLINE
    header_lines.push 'localization_priority: Priority' + NEWLINE
    header_lines.push "author: \"#{$options[:author]}\"" + NEWLINE
    header_lines.push "ms.prod: \"#{$options[:product]}\"" + NEWLINE
    header_lines.push '---' + TWONEWLINES
  end

  # Create separate actions and functions file
  def self.create_method_mdfile(method = {}, auto_file_name = nil, path_append = '')
    action_lines = []

    # Header and description
    h1name = if method[:displayName].empty?
               "#{@json_hash[:name]}: #{method[:name]}"
             else
               method[:displayName].to_s
             end

    description = method[:description].empty? ? 'PROVIDE DESCRIPTION HERE' : method[:description].to_s

    # YAML Header
    action_lines = get_yaml_header(h1name, description)

    action_lines.push HEADER1 + h1name + TWONEWLINES

    action_lines.push BETA_DISCLAIMER + TWONEWLINES if $options[:version].casecmp('beta').zero?

    action_lines.push description + TWONEWLINES

    action_lines.push PREREQ

    ### HTTP request
    # Select only the keys (that contains the REST path) for which the value (display or not flag)
    # is set to true.
    #
    action_lines.push HEADER2 + 'HTTP request' + TWONEWLINES
    action_lines.push '<!-- { "blockType": "ignored" } -->' + TWONEWLINES
    action_lines.push '```http' + NEWLINE

    http_syntax = get_syntax(method[:name], top_rest_path, path_append, method)
    action_lines.push http_syntax.join(NEWLINE) + NEWLINE
    action_lines.push '```' + TWONEWLINES

    # Path parameters
    # Cannot detect from metadata, so skip

    # Function parameters
    if method[:isFunction] && !method[:parameters].nil? && !method[:parameters].empty?
      action_lines.push HEADER2 + 'Function parameters' + TWONEWLINES
      action_lines.push 'In the request URL, provide following query parameters with values.' + TWONEWLINES
      action_lines.push PARAM_HEADER + TABLE_2ND_LINE

      method[:parameters].each do |param|
        # Append optional and enum possible values (if applicable).
        final_param_desc = param[:isRequired] ? param[:description] : 'Optional. ' + param[:description]

        if !param[:enumName].nil? && @enum_hash.key?(param[:enumName])
          append_enum = ' Possible values are: `' + @enum_hash[param[:enumName]]['options'].keys.join('`, `') + '`.'
          final_param_desc += append_enum
        end
        data_type = param[:dataType]
        data_type += ' collection' if param[:isCollection]
        action_lines.push PIPE + param[:name] + PIPE + data_type + PIPE + final_param_desc + PIPE + NEWLINE
      end
      action_lines.push NEWLINE
    end

    # Query parameters/Optional query parameters
    # Cannot detect from metadata, so skip
    if method[:name] == 'auto_get' || method[:name] == 'auto_list'
      # Handle Query Params:::
    end

    # Request headers
    action_lines.push HEADER2 + 'Request headers' + TWONEWLINES
    action_lines.push HTTP_HEADER
    action_lines.push TABLE_2ND_LINE_2COL
    action_lines.push HTTP_HEADER_SAMPLE + TWONEWLINES

    # Request body
    action_lines.push HEADER2 + 'Request body' + TWONEWLINES

    # Provide parameters:
    if !method[:isFunction] && !method[:parameters].nil? && !method[:parameters].empty?
      action_lines.push 'In the request body, provide a JSON object with the following parameters.' + TWONEWLINES
      action_lines.push PARAM_HEADER + TABLE_2ND_LINE
      method[:parameters].each do |param|
        # Append optional and enum possible values (if applicable).
        final_param_desc = param[:isRequired] ? param[:description] : 'Optional. ' + param[:description]

        if !param[:enumName].nil? && @enum_hash.key?(param[:enumName])
          append_enum = ' Possible values are: `' + @enum_hash[param[:enumName]]['options'].keys.join('`, `') + '`.'
          final_param_desc += append_enum
        end
        data_type = param[:dataType]
        data_type += ' collection' if param[:isCollection]
        action_lines.push PIPE + param[:name] + PIPE + data_type + PIPE + final_param_desc + PIPE + NEWLINE
      end
      action_lines.push NEWLINE
    else
      case method[:name]
      when 'auto_post'
        action_lines.push "In the request body, supply a JSON representation of [#{method[:returnType]}](../resources/#{method[:returnType].downcase}.md) object." + TWONEWLINES
      else
        action_lines.push 'Do not supply a request body for this method.' + TWONEWLINES
      end
    end

    # Response body
    action_lines.push HEADER2 + 'Response' + TWONEWLINES

    if !method[:returnType].nil?
      data_type_plus_link = if SIMPLETYPES.include?(method[:returnType]) || method[:returnType] == 'None'
                              method[:returnType]
                            else
                              '[' + method[:returnType] + '](../resources/' + sanitize_file_name(method[:returnType].downcase) + '.md)'
                            end

      data_type_plus_link += ' collection' if method[:isReturnTypeCollection]
    else
      data_type_plus_link = 'none'
    end

    if method[:returnType].nil? || method[:returnType] == 'None'
      action_lines.push "If successful, this method returns `#{method[:httpSuccessCode]}, #{HTTP_CODES[method[:httpSuccessCode]]}` response code. It does not return anything in the response body." + NEWLINE
    else
      action_lines.push "If successful, this method returns `#{method[:httpSuccessCode]}, #{HTTP_CODES[method[:httpSuccessCode]]}` response code and #{data_type_plus_link} object in the response body." + NEWLINE
    end

    # Write example files
    example_lines = case method[:name]
                    when 'auto_post'
                      gen_example('auto_post', method, path_append)
                    when 'auto_delete'
                      gen_example('auto_delete', method)
                    else
                      gen_example(method[:name], method)
                    end

    action_lines.push NEWLINE

    example_lines.each do |line|
      action_lines.push line
    end

    action_lines.push NEWLINE + uuid_date + NEWLINE
    action_lines.push get_json_page_annotation(h1name)

    # Write the output file.
    file_name = if auto_file_name
                  sanitize_file_name(auto_file_name)
                else
                  sanitize_file_name("#{@json_hash[:name].downcase}-#{method[:name].downcase}.md")
                end

    outfile = MARKDOWN_API_FOLDER + file_name

    file = File.new(outfile, 'w')
    action_lines.each do |line|
      file.write line
    end
    file.close
    @method_files_created += 1
  end

  def self.create_get_method(path_append = nil, file_name_override = nil)
    # Header and description
    real_header = @json_hash[:collectionOf] ? ('List ' + @json_hash[:name]) : ('Get ' + @json_hash[:name])
    description = if @json_hash[:collectionOf]
                    "Retrieve a list of #{@json_hash[:collectionOf].downcase} objects."
                  else
                    "Retrieve the properties and relationships of #{@json_hash[:name].downcase} object."
                  end

    # YAML Header
    get_method_lines = get_yaml_header(real_header, description)

    get_method_lines.push HEADER1 + real_header + TWONEWLINES

    get_method_lines.push BETA_DISCLAIMER + TWONEWLINES if $options[:version].casecmp('beta').zero?

    get_method_lines.push description + TWONEWLINES

    get_method_lines.push PREREQ
    # HTTP request
    get_method_lines.push HEADER2 + 'HTTP request' + TWONEWLINES
    get_method_lines.push '<!-- { "blockType": "ignored" } -->' + TWONEWLINES

    get_method_lines.push '```http' + NEWLINE
    http_syntax = if @json_hash[:collectionOf]
                    get_syntax('auto_list', top_rest_path, path_append)
                  else
                    get_syntax('auto_get', top_rest_path)
                  end

    get_method_lines.push http_syntax.join(NEWLINE) + NEWLINE
    get_method_lines.push '```' + TWONEWLINES

    # Query parameters
    get_method_lines.push HEADER2 + 'Optional query parameters' + TWONEWLINES
    get_method_lines.push 'This method supports some of the OData query parameters to help customize the response. For general information, see [OData Query Parameters](/graph/query-parameters)' + TWONEWLINES

    # if @json_hash[:collectionOf]
    #   get_method_lines.push QRY_HEADER + NEWLINE
    #   get_method_lines.push QRY_2nd_LINE + NEWLINE

    #   # countable, expandable, selectable, filterable, skipSupported, topSupported, sortable = true, true, true, true, true, true, true
    #   # annotationTarget = @annotations[@json_hash[:collectionOf].downcase]

    #   # if annotationTarget
    #   #   countable = annotationTarget["countrestrictions/countable"].nil? ? true : annotationTarget["countrestrictions/countable"]
    #   #   expandable = annotationTarget["expandrestrictions/expandable"].nil? ? true : annotationTarget["expandrestrictions/expandable"]
    #   #   selectable = annotationTarget["selectrestrictions/selectable"].nil? ? true : annotationTarget["selectrestrictions/selectable"]
    #   #   filterable = annotationTarget["filterrestrictions/filterable"].nil? ? true : annotationTarget["filterrestrictions/filterable"]
    #   #   skipSupported = annotationTarget["skipsupported"].nil? ? true : annotationTarget["skipsupported"]
    #   #   topSupported = annotationTarget["topsupported"].nil? ? true : annotationTarget["topsupported"]
    #   #   sortable = annotationTarget["sortrestrictions/sortable"].nil? ? true : annotationTarget["sortrestrictions/sortable"]
    #   # end
    #   # if countable
    #   #   get_method_lines.push QRY_COUNT +  NEWLINE
    #   # end
    #   # if expandable
    #   #   get_method_lines.push QRY_EXPAND + "See relationships table of [#{@json_hash[:collectionOf]}](../resources/#{@json_hash[:collectionOf].downcase}.md) for supported names. |" + NEWLINE
    #   # end
    #   # if filterable
    #   #   get_method_lines.push QRY_FILTER + NEWLINE
    #   # end
    #   # if sortable
    #   #   get_method_lines.push QRY_ORDERBY + NEWLINE
    #   # end
    #   # if selectable
    #   #   get_method_lines.push QRY_SELECT + NEWLINE
    #   # end
    #   # if skipSupported
    #   #   get_method_lines.push QRY_SKIP + NEWLINE
    #   #   get_method_lines.push QRY_SKIPTOKEN + NEWLINE
    #   # end
    #   # if topSupported
    #   #   get_method_lines.push QRY_TOP + NEWLINE
    #   # end
    # else
    #   countable, expandable, selectable  = true, true, true
    #   annotationTarget = @annotations[@json_hash[:name].downcase]

    #   if annotationTarget
    #     countable = annotationTarget["countrestrictions/countable"].nil? ? true : annotationTarget["countrestrictions/countable"]
    #     expandable = annotationTarget["expandrestrictions/expandable"].nil? ? true : annotationTarget["expandrestrictions/expandable"]
    #     selectable = annotationTarget["selectrestrictions/selectable"].nil? ? true : annotationTarget["selectrestrictions/selectable"]
    #   end
    #   if annotationTarget && !countable && !expandable && !selectable
    #   else
    #     get_method_lines.push QRY_HEADER + NEWLINE
    #     get_method_lines.push QRY_2nd_LINE + NEWLINE
    #     if countable
    #       get_method_lines.push QRY_COUNT + NEWLINE
    #     end
    #     if expandable
    #       get_method_lines.push QRY_EXPAND + "See relationships table of [#{@json_hash[:name]}](../resources/#{@json_hash[:name].downcase}.md) object for supported names. |" + NEWLINE
    #     end
    #     if selectable
    #       get_method_lines.push QRY_SELECT + NEWLINE
    #     end
    #   end
    # end

    # Request headers
    get_method_lines.push HEADER2 + 'Request headers' + TWONEWLINES
    get_method_lines.push '| Name      |Description|' + NEWLINE
    get_method_lines.push '|:----------|:----------|' + NEWLINE
    get_method_lines.push HTTP_HEADER_SAMPLE + TWONEWLINES

    # Request body
    get_method_lines.push HEADER2 + 'Request body' + TWONEWLINES
    get_method_lines.push 'Do not supply a request body for this method.' + TWONEWLINES

    # Response body
    get_method_lines.push HEADER2 + 'Response' + TWONEWLINES
    if @json_hash[:collectionOf]
      get_method_lines.push "If successful, this method returns a `200 OK` response code and collection of [#{@json_hash[:collectionOf]}](../resources/#{sanitize_file_name(@json_hash[:collectionOf].downcase)}.md) objects in the response body." + TWONEWLINES
    else
      get_method_lines.push "If successful, this method returns a `200 OK` response code and [#{@json_hash[:name]}](../resources/#{sanitize_file_name(@json_hash[:name].downcase)}.md) object in the response body." + TWONEWLINES
    end

    # Example
    example_lines = if @json_hash[:collectionOf]
                      gen_example('auto_list', nil, path_append)
                    else
                      gen_example('auto_get')
                    end

    example_lines.each do |line|
      get_method_lines.push line
    end

    get_method_lines.push NEWLINE + uuid_date + NEWLINE
    get_method_lines.push get_json_page_annotation(real_header)

    # Write the output file.
    file_name = @json_hash[:collectionOf] ? "#{sanitize_file_name(@json_hash[:collectionOf].downcase)}-list.md" : "#{sanitize_file_name(@json_hash[:name].downcase)}-get.md"

    outfile = if file_name_override
                MARKDOWN_API_FOLDER + file_name_override
              else
                MARKDOWN_API_FOLDER + file_name
              end

    file = File.new(outfile, 'w')
    get_method_lines.each do |line|
      file.write line
    end
    file.close
    @get_list_files_created += 1
  end

  def self.create_patch_method(properties = [])
    # Header and description
    h1name = ''
    description = ''
    if @json_hash[:updateDescription].empty?
      h1name = "Update #{@json_hash[:name].downcase}"
      description = "Update the properties of #{@json_hash[:name].downcase} object."
    else
      h1name = @json_hash[:updateDescription].to_s
      description = @json_hash[:updateDescription].to_s
    end

    # YAML Header
    patch_method_lines = get_yaml_header(h1name, description)

    patch_method_lines.push HEADER1 + h1name + TWONEWLINES

    patch_method_lines.push BETA_DISCLAIMER + TWONEWLINES if $options[:version].casecmp('beta').zero?

    patch_method_lines.push description + TWONEWLINES

    patch_method_lines.push PREREQ
    # HTTP request
    patch_method_lines.push HEADER2 + 'HTTP request' + TWONEWLINES
    patch_method_lines.push '<!-- { "blockType": "ignored" } -->' + TWONEWLINES
    patch_method_lines.push '```http' + NEWLINE
    # httpPatchArray = @json_hash[:restPath].map {|a| 'PATCH ' + a.to_s}
    # patch_method_lines.push httpPatchArray.join(NEWLINE) + NEWLINE

    http_syntax = get_syntax('auto_patch', top_rest_path)
    patch_method_lines.push http_syntax.join(NEWLINE) + NEWLINE
    patch_method_lines.push '```' + TWONEWLINES

    # Request headers
    patch_method_lines.push HEADER2 + 'Request headers' + TWONEWLINES
    patch_method_lines.push '| Name       | Description|' + NEWLINE
    patch_method_lines.push '|:-----------|:-----------|' + NEWLINE
    patch_method_lines.push HTTP_HEADER_SAMPLE + TWONEWLINES

    # Request body
    patch_method_lines.push HEADER2 + 'Request body' + TWONEWLINES
    patch_method_lines.push "In the request body, supply the values for relevant fields that should be updated. Existing properties that are not included in the request body will maintain their previous values or be recalculated based on changes to other property values. For best performance you shouldn't include existing values that haven't changed." + TWONEWLINES

    patch_method_lines.push PROPERTY_HEADER + TABLE_2ND_LINE
    properties.each do |prop|
      next if prop[:isReadOnly]

      final_desc = prop[:description]
      if !prop[:enumName].nil? && @enum_hash.key?(prop[:enumName])
        append_enum = ' Possible values are: `' + @enum_hash[prop[:enumName]]['options'].keys.join('`, `') + '`.'
        final_desc += append_enum
      end
      data_type = prop[:dataType]
      data_type += ' collection' if prop[:isCollection]
      patch_method_lines.push PIPE + prop[:name] + PIPE + data_type + PIPE + final_desc + PIPE + NEWLINE
    end
    patch_method_lines.push NEWLINE

    # Response body
    patch_method_lines.push HEADER2 + 'Response' + TWONEWLINES
    patch_method_lines.push "If successful, this method returns a `200 OK` response code and updated [#{@json_hash[:name]}](../resources/#{sanitize_file_name(@json_hash[:name].downcase)}.md) object in the response body." + TWONEWLINES

    # Example
    example_lines = gen_example('auto_patch')
    example_lines.each do |line|
      patch_method_lines.push line
    end
    patch_method_lines.push NEWLINE + uuid_date + NEWLINE
    patch_method_lines.push get_json_page_annotation(h1name)

    # Write the output file.
    file_name = "#{sanitize_file_name(@json_hash[:name].downcase)}-update.md"
    outfile = MARKDOWN_API_FOLDER + file_name
    file = File.new(outfile, 'w')
    patch_method_lines.each do |line|
      file.write line
    end
    file.close
    @patch_files_created += 1
  end

  # Conversion to specification
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def self.convert_to_spec(item = nil)
    is_post = nil
    @json_hash = JSON.parse(item, symbolize_names: true)

    if @json_hash[:isEntitySet]
      @ientityset += 1
      @serviceroot.push @json_hash
      return
    end

    # Obtain the resource name.
    @resource = @json_hash[:name]
    puts "--> #{@resource}"

    properties = @json_hash[:properties]
    properties = properties.sort_by { |v| v[:name] } if properties && properties.length > 1

    methods = @json_hash[:methods]
    methods = methods.sort_by { |v| v[:name] } if !methods.nil? && methods.length > 1

    title = @json_hash[:name] + ' resource type'
    description = @json_hash[:description].empty? ? 'PROVIDE DESCRIPTION HERE' : @json_hash[:description]

    # YAML Header
    @mdlines = get_yaml_header(title, description)

    # Header and description
    @mdlines.push HEADER1 + title + TWONEWLINES

    @mdlines.push BETA_DISCLAIMER + TWONEWLINES if $options[:version].casecmp('beta').zero?

    @mdlines.push description + TWONEWLINES

    # Determine if there is/are: relations, properties and methods.
    is_relation, is_property, is_method, patchable = false

    properties.each do |prop|
      if prop[:isRelationship]
        is_relation = true
        is_post = true if prop[:isCollection] && prop[:allowPostToCollection]
      else
        is_property = true
        patchable = true if !prop[:isReadOnly] && @json_hash[:allowPatch]
      end
    end

    is_method = true if methods

    # Add method table.
    unless @json_hash[:isComplexType]
      @mdlines.push HEADER2 + 'Methods' + TWONEWLINES
      @mdlines.push TASKS_HEADER + TABLE_2ND_LINE if is_method || is_property || is_post || @json_hash[:allowDelete]

      unless @json_hash[:isComplexType]
        if @json_hash[:collectionOf]
          return_link = '[' + @json_hash[:collectionOf] + '](' + sanitize_file_name(@json_hash[:collectionOf].downcase) + '.md)'
          @mdlines.push "|[List](../api/#{sanitize_file_name(@json_hash[:collectionOf].downcase)}-list.md) | #{return_link} collection |Get #{uncapitalize @json_hash[:collectionOf]} object collection. |" + NEWLINE
        elsif is_property
          return_link = '[' + @json_hash[:name] + '](' + @json_hash[:name].downcase + '.md)'
          @mdlines.push "| [Get #{@json_hash[:name]}](../api/#{sanitize_file_name(@json_hash[:name].downcase)}-get.md) | #{return_link} | Read properties and relationships of #{uncapitalize @json_hash[:name]} object. |" + NEWLINE
        end
        create_get_method
      end

      # Run through all the collection relationships and add a task for posting
      # to the right resouce to create the object.
      # Based on the data type, the name of the API varies.
      if is_post
        properties.each do |prop|
          next unless prop[:isRelationship] && prop[:isCollection] && prop[:allowPostToCollection]

          use_name = if SIMPLETYPES.include?(prop[:dataType]) || POST_NAME_MAPPING.include?(prop[:dataType].downcase)
                       prop[:name].chomp('s')
                     else
                       prop[:dataType]
                     end
          post_name = 'Create ' + use_name
          file_name = sanitize_file_name("#{@json_hash[:name].downcase}-post-#{prop[:name].downcase}.md")
          post_link = "../api/#{file_name}"
          return_link = if SIMPLETYPES.include? prop[:dataType]
                          prop[:dataType]
                        else
                          '[' + prop[:dataType] + '](' + sanitize_file_name(prop[:dataType].downcase) + '.md)'
                        end
          @mdlines.push "| [#{post_name}](#{post_link}) | #{return_link} | Create a new #{use_name} by posting to the #{prop[:name]} collection. |" + NEWLINE
          unless File.exist?("#{MARKDOWN_API_FOLDER}/#{file_name}")
            mtd = deep_copy(@struct[:method])

            mtd[:name] = 'auto_post'
            mtd[:displayName] = post_name
            mtd[:returnType] = prop[:dataType]
            mtd[:description] = get_create_description(mtd[:returnType], use_name)

            mtd[:parameters] = nil
            mtd[:httpSuccessCode] = '201'
            create_method_mdfile(mtd, file_name, prop[:name])
          end

          # Add List method.
          next if SIMPLETYPES.include? prop[:dataType]

          file_name = sanitize_file_name("#{@json_hash[:name]}-list-#{prop[:name]}.md".downcase)
          list_link = "../api/#{file_name}"

          @mdlines.push "| [List #{prop[:name]}](#{list_link}) | #{return_link} collection | Get a #{use_name} object collection. |" + NEWLINE
          save_json_hash = deep_copy @json_hash
          @json_hash[:name] = prop[:name]
          @json_hash[:collectionOf] = prop[:dataType]
          create_get_method(prop[:name], file_name)
          @json_hash = deep_copy save_json_hash
          @list_from_rel += 1
        end
      end

      if patchable
        return_link = '[' + @json_hash[:name] + '](' + sanitize_file_name(@json_hash[:name].downcase) + '.md)'
        @mdlines.push "| [Update](../api/#{sanitize_file_name(@json_hash[:name].downcase)}-update.md) | #{return_link} | Update #{@json_hash[:name]} object. |" + NEWLINE
        create_patch_method properties
        # mtd = deep_copy(@struct[:method])
        # mtd[:name] = 'auto_patch'
        # mtd[:displayName] = 'Update'
        # mtd[:returnType] = @json_hash[:name]
        # mtd[:description] = "Update @json_hash[:name]."
        # mtd[:parameters] = nil
        # mtd[:httpSuccessCode] = '200'
        # create_method_mdfile(mtd, "#{@json_hash[:name].downcase}_update.md")
      end

      if @json_hash[:allowDelete]
        @mdlines.push "| [Delete](../api/#{sanitize_file_name(@json_hash[:name].downcase)}-delete.md) | None | Delete #{@json_hash[:name]} object. |" + NEWLINE
        mtd = deep_copy(@struct[:method])
        mtd[:displayName] = "Delete #{@json_hash[:name]}"
        mtd[:name] = 'auto_delete'

        mtd[:description] = if @json_hash[:deleteDescription].empty?
                              "Delete #{@json_hash[:name]}."
                            else
                              @json_hash[:deleteDescription]
                            end
        mtd[:httpSuccessCode] = '204'
        mtd[:parameters] = nil
        create_method_mdfile(mtd, "#{sanitize_file_name(@json_hash[:name].downcase)}-delete.md")
      end

      if is_method
        methods.each do |method|
          push_method method
        end
        @mdlines.push NEWLINE
      end

      @mdlines.push 'None' + TWONEWLINES if !is_property && !is_method && !is_post

      @mdlines.push NEWLINE + ALERT_NOTE + @json_hash[:methodNotes].to_s + TWONEWLINES unless @json_hash[:methodNotes].empty?
    end

    # Add property table.

    @mdlines.push HEADER2 + 'Properties' + TWONEWLINES
    if is_property
      @mdlines.push PROPERTY_HEADER + TABLE_2ND_LINE
      properties.each do |prop|
        push_property prop unless prop[:isRelationship]
      end
      @mdlines.push NEWLINE
      @mdlines.push NEWLINE + ALERT_NOTE + @json_hash[:propertyNotes].to_s + TWONEWLINES unless @json_hash[:propertyNotes].empty?
    else
      @mdlines.push 'None' + TWONEWLINES
    end

    # Add Relationship table.
    unless @json_hash[:isComplexType]
      @mdlines.push HEADER2 + 'Relationships' + TWONEWLINES
      if is_relation
        @mdlines.push RELATIONSHIP_HEADER + TABLE_2ND_LINE
        properties.each do |prop|
          push_property prop if prop[:isRelationship]
        end
        @mdlines.push NEWLINE
        @mdlines.push NEWLINE + ALERT_NOTE + @json_hash[:relationshipNotes].to_s + TWONEWLINES unless @json_hash[:relationshipNotes].empty?
      else
        @mdlines.push 'None' + TWONEWLINES
      end
    end

    # Header and description
    if !@json_hash[:isEntitySet] && is_property
      @mdlines.push HEADER2 + 'JSON representation' + TWONEWLINES
      @mdlines.push 'The following is a JSON representation of the resource.' + TWONEWLINES

      @mdlines.push get_json_model_pretext(@json_hash[:name], properties, @json_hash[:baseType]) + TWONEWLINES

      @mdlines.push '```json' + NEWLINE
      # @mdlines.push get_json_model(properties) + TWONEWLINES
      jsonpretty = pretty_json(get_json_model(properties))
      @mdlines.push jsonpretty + NEWLINE

      @mdlines.push '```' + TWONEWLINES
    end

    @mdlines.push uuid_date + NEWLINE

    # do we need this for tool check?
    @mdlines.push get_json_page_annotation(@json_hash[:name] + ' resource')

    # Write the output file.
    outfile = if @json_hash[:isEntitySet]
                MARKDOWN_RESOURCE_FOLDER + sanitize_file_name(@resource.downcase) + '-collection.md'
              else
                MARKDOWN_RESOURCE_FOLDER + sanitize_file_name(@resource.downcase) + '.md'
              end
    file = File.new(outfile, 'w')
    @mdlines.each do |line|
      file.write line
    end
    file.close
    @resources_files_created += 1
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def self.create_service_root
    # YAML Header
    service_lines = get_yaml_header('Service root', 'Service root')

    service_lines.push HEADER1 + 'Service root' + TWONEWLINES

    service_lines.push BETA_DISCLAIMER + TWONEWLINES if $options[:version].casecmp('beta').zero?

    service_lines.push NEWLINE + HEADER2 + 'Methods' + TWONEWLINES
    service_lines.push TASKS_HEADER + TABLE_2ND_LINE

    @serviceroot.each do |item|
      next unless item[:collectionOf]

      post_name = "Create #{item[:collectionOf]}"
      file_name = sanitize_file_name("#{item[:collectionOf].downcase}-post-#{item[:name].downcase}.md")
      puts "Service root file: #{file_name}"
      post_link = "../api/#{file_name}"
      return_link = '[' + item[:collectionOf] + '](' + sanitize_file_name(item[:collectionOf].downcase) + '.md)'
      service_lines.push "| [#{post_name}](#{post_link}) | #{return_link} | Create a new #{item[:collectionOf]} by posting to the #{item[:name]} collection. |" + NEWLINE
      if File.exist?("#{MARKDOWN_API_FOLDER}#{file_name}")
        puts 'EntitySet POST create file already exists!'
      else
        mtd = deep_copy(@struct[:method])
        mtd[:name] = 'auto_post'
        mtd[:displayName] = post_name
        mtd[:returnType] = item[:collectionOf]
        mtd[:description] = get_create_description(item[:collectionOf])

        mtd[:parameters] = nil
        mtd[:httpSuccessCode] = '201'
        @json_hash = item
        create_method_mdfile(mtd, file_name)
      end

      return_link = '[' + item[:collectionOf] + '](' + item[:collectionOf].downcase + '.md)'
      service_lines.push "|[List #{item[:collectionOf]}](../api/#{sanitize_file_name(item[:collectionOf].downcase)}-list.md) | #{return_link} collection |Get #{uncapitalize item[:collectionOf]} object collection. |" + NEWLINE
      @json_hash = item
      create_get_method
    end

    service_lines.push NEWLINE + uuid_date + NEWLINE
    service_lines.push get_json_page_annotation('Service root')
    outfile = MARKDOWN_RESOURCE_FOLDER + 'service-root.md'
    file = File.new(outfile, 'w')
    service_lines.each do |line|
      file.write line
    end
    file.close
  end

  def self.generate_enums
    enum_lines = []

    # YAML Header
    enum_lines.push '---' + NEWLINE
    enum_lines.push 'title: "Enumerations"' + NEWLINE
    enum_lines.push 'description: "File to contain enumeration definitions"' + NEWLINE
    enum_lines.push '---' + TWONEWLINES

    @enum_hash.each do |key, value|
      enum_lines.push HEADER3 + key + TWONEWLINES
      enum_lines.push ENUM_HEADER
      enum_lines.push TABLE_2ND_LINE_2COL

      if value.key? 'options'
        value['options'].each do |member, mem_val|
          enum_lines.push PIPE + member + PIPE + (mem_val['value'].nil? ? '' : mem_val['value']) + PIPE + NEWLINE
        end
      else
        enum_lines.push PIPE + 'EMPTY ENUM?' + PIPE + PIPE + NEWLINE
      end
      enum_lines.push NEWLINE
    end

    enum_file = MARKDOWN_RESOURCE_FOLDER + 'enums.md'
    file = File.new(enum_file, 'w')
    enum_lines.each do |line|
      file.write line
    end
    file.close
  end

  #####
  # Main loop. Process each JSON files.
  #
  ###
  processed_files = 0
  Dir.foreach(JSON_SOURCE_FOLDER) do |item|
    next if ['.', '..'].include?(item)

    fullpath = JSON_SOURCE_FOLDER + item.downcase

    if File.file?(fullpath)
      convert_to_spec File.read(fullpath, encoding: 'UTF-8')
      processed_files += 1
    end
  end
  create_service_root
  generate_enums

  puts ''
  puts "*** OK. Processed #{processed_files} input files. Check #{File.expand_path(LOG_FOLDER)} folder for results. ***"
  puts "*** @resources_files_created #{@resources_files_created}"
  puts "*** @get_list_files_created #{@get_list_files_created} "
  puts "*** @patch_files_created #{@patch_files_created}"
  puts "*** @method_files_created #{@method_files_created}"
  puts "*** @list_from_relationships #{@list_from_rel}"
  puts "*** @ientityset #{@ientityset}"
end
