module Agents
  class DktDocumentStorageStoreAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include DktNifApiAgentConcern
    include FileHandling

    consumes_file_pointer!

    default_schedule 'never'

    description do
      <<-MD
        The `DktDocumentStorageStoreAgent` uploads documents to the DKT platform. Each uploaded document will also processed by a series of Natural Language Processing services, the results will be stored in the e-Sesame triple store.

        The Agent accepts all configuration options of the `/document-storage/collections` endpoint as of september 2016, have a look at the [offical documentation](https://github.com/dkt-projekt/e-document-storage) if you need additional information

        All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

        `url` allows to customize the endpoint of the API when hosting the DKT services elswhere (not including the collection_name).

        `body` use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify data to upload.

        `collection_name` Name of the collection.

        `file_name` Name of the file uploaded.

        #{common_nif_agent_fields_description}

        **When receiving a file pointer:**

        `content_type` and `file_name` can optionally be used to override the file name and content-type of the received file.

        #{receiving_file_handling_agent_description}
      MD
    end

    def default_options
      {
        'url' => '',
        'body' => '{{ data }}',
      }
    end

    form_configurable :url
    form_configurable :body, type: :text
    form_configurable :collection_name
    form_configurable :fileName
    form_configurable :content_type
    common_nif_agent_fields

    def validate_options
      errors.add(:base, "url needs to be present") if options['url'].blank?
      errors.add(:base, "url must not have a trailing slash") if options['url'].end_with?('/')
      validate_web_request_options!
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)
        if io = get_io(event)
          mo['fileName']     = File.basename(event.payload['file_pointer']['file']) if mo['fileName'].blank?
          mo['content_type'] = MIME::Types.type_for(mo['fileName']).first.try(:content_type) if mo['content_type'].blank?
          mo['body']         = io

          logger.warn('No content-type has been set.') if mo['content_type'].blank?
          mo['body_format'] = mo.delete('content_type') || 'text/plain'

          nif_request!(mo, [], mo['url'] + "/#{mo['collection_name']}?fileName=#{CGI.escape(mo['fileName'])}", headers: {'Transfer-Encoding' => 'chunked'}, event: event)
        else
          mo['body_format'] = mo.delete('content_type') || 'text/plain'
          nif_request!(mo, ['fileName', 'file'], mo['url'] + "/#{mo['collection_name']}", event: event)
        end
      end
    end
  end
end
