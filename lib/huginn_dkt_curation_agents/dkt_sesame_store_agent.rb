module Agents
  class DktSesameStoreAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include DktNifApiAgentConcern

    default_schedule 'never'

    description <<-MD
      The `DktSesameStoreAgent` stores semantic information in a triple storage system using the DKT API.

      The Agent accepts all configuration options of the `/e-sesame/storeData` endpoint as of september 2016, have a look at the [offical documentation](https://github.com/dkt-projekt/e-Sesame#storage-of-semantic-information) if you need additional information.

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `url` allows to customize the endpoint of the API when hosting the DKT services elswhere.

      `storageName`: name of the sesame (triple storage) where the information must be stored.

      `storagePath`: path of the sesame (triple storage) where the information must be stored, set it to `/opt/tmp/storage/sesameStorage/`

      `storageCreate`: boolean value defining if the repository has to be created.

      `inputDataFormat`: parameter that specifies the format in which the information is provided to the service. It can have three different values: `body`, or `triple`.

      #{common_nif_agent_fields_description}

      **If the `inputDataFormat` is `body`:**

      `body` use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify the data to be send to the API.

      `inputDataMimeType`: in case that the service is receiving a string, this parameter specifies the mime type of the string (`text/turtle`, `application/rdf+xml` or `application/ld+json`).

      **If the `inputDataFormat` is `triple`: the information to be stored is given as a triple defined by its three properties:**

      `subject`: subject of the triple.

      `predicate`: predicate of the triple.

      `object`: object of the triple.

    MD

    def default_options
      {
        'url' => '',
        'body' => '{{ data }}',
        'storageCreate' => 'true',
        'inputDataFormat' => 'body',
        'inputDataMimeType' => 'text/turtle',
      }
    end

    form_configurable :url
    form_configurable :storageName
    form_configurable :storagePath
    form_configurable :storageCreate, type: :boolean
    form_configurable :inputDataFormat, type: :array, values: ['body', 'triple']
    form_configurable :inputDataMimeType, type: :array, values: ['text/turtle', 'application/ld+json', 'application/rdf+xml']
    form_configurable :body
    form_configurable :subject
    form_configurable :predicate
    form_configurable :object
    common_nif_agent_fields

    def validate_options
      errors.add(:base, "url needs to be present") if options['url'].blank?
      errors.add(:base, "storageName needs to be present") if options['storageName'].blank?
      errors.add(:base, "storagePath needs to be present") if options['storagePath'].blank?
      validate_web_request_options!
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)

        keys = if mo['inputDataFormat'] == 'body'
          mo['body_format'] = mo['inputDataMimeType']
          ['storageName', 'storagePath', 'storageCreate', 'inputDataFormat', 'inputDataMimeType']
        else
          mo.delete('body')
          ['storageName', 'storagePath', 'storageCreate', 'inputDataFormat', 'inputDataMimeType', 'subject', 'predicate', 'object']
        end

        nif_request!(mo, keys, mo['url'], event: event)
      end
    end
  end
end
