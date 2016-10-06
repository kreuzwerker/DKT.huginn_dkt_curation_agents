module Agents
  class DktDocumentStorageQueryAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include DktNifApiAgentConcern

    default_schedule 'never'

    description <<-MD
      The `DktDocumentStorageQueryAgent` queres the DKT Document Storage for the contents or status of a collection.

      The Agent accepts all configuration options of the `/document-storage/collections` endpoint as of september 2016, have a look at the [offical documentation](https://github.com/dkt-projekt/e-document-storage) if you need additional information

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `url` allows to customize the endpoint of the API when hosting the DKT services elswhere (not including the collection_name).

      `collection_name` Name of the collection.

      `mode`:`documents` returns all documents of the collection, `status` returns the status of the collection

      #{common_nif_agent_fields_description}
    MD

    def default_options
      {
        'url' => '',
        'mode' => 'list'
      }
    end

    form_configurable :url
    form_configurable :collection_name
    form_configurable :mode, type: :array, values: ['documents', 'status']
    common_nif_agent_fields

    def validate_options
      errors.add(:base, "url needs to be present") if options['url'].blank?
      errors.add(:base, "url must not have a trailing slash") if options['url'].end_with?('/')
      validate_web_request_options!
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)

        mo['body_format'] = mo.delete('content_type') || 'text/plain'
        nif_request!(mo, [], mo['url'] + "/#{mo['collection_name']}/#{mo['mode']}", parse_response: :json, method: :get, event: event)
      end
    end
  end
end
