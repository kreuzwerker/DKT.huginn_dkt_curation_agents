module Agents
  class DktDocumentClassificationAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include NifApiAgentConcern

    default_schedule 'never'

    description <<-MD
      The `DktDocumentClassificationAgent` determines the class of a given text using the DKT API.

      The different available classes depend on the model that is used (see next section).

      The Agent accepts all configuration options of the `/e-documentclassification` endpoint as of march 2016, have a look at the [offical documentation](https://not-up-to-date.com) if you need additional information

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `url` allows to customize the endpoint of the API when hosting the DKT services elswhere.

      `input` use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify the data to be send to the API.

      `informat` specify the content-type of the data in `body`

      `outformat` requested RDF serialization format of the output

      `language` language of the source data

      `modelName` the model that is used for text classification. There are some models available:

        * `3pc`: model generated using the data provided by 3pc (Mendelsohn letters) and their categories.
        * `condat_types`: model generated using the data provided by Condat and the types associated to every document.
        * `condat_categories`: model generated using the data provided by Condat and the categories associated to every document.
        * `kreuzwerker_categories`: model generated using the data provided by Kreuzwerker and the categories associated to every document.
        * `kreuzwerker_subcategories`: model generated using the data provided by Kreuzwerker and the subcategories associated to every document.
        * `kreuzwerker_topics`: model generated using the data provided by Kreuzwerker and the topics associated to every document.

      `modelPath` [optional] this parameter is only used is other location for models is used inside the server. This parameter has been meant for local installation of the service.

    MD

    def default_options
      {
        'url' => '',
        'input' => '{{ data }}',
        'informat' => 'text/plain',
        'outformat' => 'turtle',
        'language' => 'de',
        'modelName' => '3pc',
        'modelPath' => ''
      }
    end

    form_configurable :url
    form_configurable :input
    form_configurable :informat, type: :array, values: ['text/plain', 'text/xml', 'text/n3', 'text/turtle', 'application/ld+json', 'application/n-triples', 'application/rdf+xml']
    form_configurable :outformat, type: :array, values: ['turtle', 'json-ld', 'n3', 'n-triples', 'rdf-xml', 'text/html']
    form_configurable :language, type: :array, values: ['de']
    form_configurable :modelName, type: :array, values: ['3pc', 'condat_types', 'condat_categories', 'kreuzwerker_categories', 'kreuzwerker_subcategories', 'kreuzwerker_topics']
    form_configurable :modelPath

    def validate_options
      errors.add(:base, "url needs to be present") if options['url'].blank?
      errors.add(:base, "input needs to be present") if options['input'].blank?
      validate_web_request_options!
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)

        nif_request!(mo, ['outformat', 'modelName', 'input', 'informat', 'modelPath', 'language'], mo['url'])
      end
    end
  end
end
