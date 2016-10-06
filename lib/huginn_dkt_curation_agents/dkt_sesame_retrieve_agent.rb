module Agents
  class DktSesameRetrieveAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include DktNifApiAgentConcern

    default_schedule 'never'

    description <<-MD
      The `DktSesameRetrieveAgent` retrieves semantic information from a triple storage system using the DKT API.

      The Agent accepts all configuration options of the `/e-sesame/retrieveData` endpoint as of september 2016, have a look at the [offical documentation](https://github.com/dkt-projekt/e-Sesame#retrieval-of-semantic-information) if you need additional information.

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `url` allows to customize the endpoint of the API when hosting the DKT services elswhere.

      `storageName`: name of the sesame (triple storage) where the information must be stored.

      `storagePath`: (optional) path of the sesame (triple storage) where the information must be stored.

      `inputDataType`: parameter that specifies the format in which the query is provided to the service. It can have four different values: `NIF`, `entity`, `sparql` or `triple`.

      #{common_nif_agent_fields_description}

      **If the `inputDataType` is `NIF`, `entity` or `sparql`:**

      `input`: use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify the data to be send to the API.

      `body_format` specify the content-type of the data in `input`

      **If the `inputDataType` is `triple`: the service will retrieve triples that fit one or more of the following elements:**

      `subject`: subject of the triple.

      `predicate`: predicate of the triple.

      `object`: object of the triple.

      `outformat` requested RDF serialization format of the output
    MD

    def default_options
      {
        'url' => '',
        'input' => '{{ data }}',
        'inputDataFormat' => 'NIF',
      }
    end

    form_configurable :url
    form_configurable :storageName
    form_configurable :storagePath
    form_configurable :body_format, type: :array, values: ['text/plain', 'text/xml', 'text/n3', 'text/turtle', 'application/ld+json', 'application/n-triples', 'application/rdf+xml']
    form_configurable :inputDataFormat, type: :array, values: ['NIF', 'entity', 'sparql', 'triple']
    form_configurable :input
    form_configurable :subject
    form_configurable :predicate
    form_configurable :object
    form_configurable :outformat, type: :array, values: ['text/turtle', 'application/json-ld', 'application/rdf-xml', 'text/html']
    common_nif_agent_fields

    def validate_options
      errors.add(:base, "url needs to be present") if options['url'].blank?
      errors.add(:base, "storageName needs to be present") if options['storageName'].blank?
      validate_web_request_options!
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)

        keys = if mo['inputDataFormat'] == 'triple'
          ['storageName', 'storagePath', 'inputDataFormat', 'subject', 'predicate', 'object', 'outformat']
        else
          ['storageName', 'storagePath', 'inputDataFormat', 'input']
        end

        nif_request!(mo, keys, mo['url'], event: event)
      end
    end
  end
end
