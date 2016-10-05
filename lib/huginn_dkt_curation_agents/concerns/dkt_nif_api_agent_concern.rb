module DktNifApiAgentConcern
  extend ActiveSupport::Concern

  included do
    can_dry_run!

    event_description <<-MD
      Events look like this:

          {
            "status": 200,
            "headers": {
              "Content-Type": "text/html",
              ...
            },
            "body": "<html>Some data...</html>"
          }
    MD
  end

  def working?
    received_event_without_error?
  end

  def check
    receive([Event.new])
  end

  private

  def nif_request!(mo, configuration_keys, url, options = {})
    headers = {
      'Content-Type' => mo['body_format']
    }.merge(options[:headers] || {})

    params = {}
    configuration_keys.each do |param|
      params[param.gsub('_', '-')] = mo[param] if mo[param].present?
    end

    response = faraday.run_request(options.fetch(:method, :post), url, mo['body'], headers) do |request|
      request.params.update(params)
    end

    body = case options[:parse_response]
           when :json
             JSON.parse(response.body)
           else
             response.body
           end

    original_payload = boolify(mo['merge']) ? options[:event].payload : {}

    create_event payload: original_payload.merge(body: body, headers: response.headers, status: response.status)
  end
end
