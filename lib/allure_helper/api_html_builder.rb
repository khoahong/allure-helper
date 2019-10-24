
class ApiHtmlBuilder
  TEMPLATE_FILEPATH = __dir__ + '/api_template.erb'

  def build_html(response)
    @response = response
    @request_body = build_request_body
    @response_body = build_response_body

    @template = File.read(TEMPLATE_FILEPATH)
    ERB.new(@template, nil, '-').result(binding)
  end

  def build_request_body
    begin
      JSON.pretty_generate(JSON.parse(@response.request.options[:body]))
    rescue StandardError
      @response.request.options[:body]
    end
  end

  def build_response_body
    begin
      JSON.pretty_generate(JSON.parse(@response.body))
    rescue StandardError
      @response.body
    end
  end
end