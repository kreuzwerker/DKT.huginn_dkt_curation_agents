module Agents
  class DktNerAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include DktNifApiAgentConcern

    default_schedule 'never'

    description <<-MD
      The `DktNerAgent` (DKT Named Entity Recognition) enriches text content with entities gathered from various datasets using the DKT API.

      The Agent accepts all configuration options of the `/e-nlp/namedEntityRecognition` endpoint as of september 2016, have a look at the [offical documentation](https://github.com/dkt-projekt/e-NLP#named-entity-recognition) if you need additional information

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `url` allows to customize the endpoint of the API when hosting the DKT services elswhere.

      `body` use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify the data to be send to the API.

      `body_format` specify the content-type of the data in `body`

      `outformat` requested RDF serialization format of the output

      `language` language of the source data

      `analysis`: The type of analysis to perform. Specify `ner` for performing NER based on a trained model. Specify `dict` to perform NER based on an uploaded dictionary. Specify `temp` to perform NER for temporal expressions.

      `mode`: Works for the `ner` analysis only. Possible values are spot (for entity spotting only), link (for entity linking only, e.g. looking up the entity label on DBPedia to retrieve a URI) or all (for both).

      `models`: Specify the model to be used for performing the analysis. Use 'manual input' to specify multiple models in a comma separated list.

      #{common_nif_agent_fields_description}
    MD

    def default_options
      {
        'url' => '',
        'body' => '{{ data }}',
        'body_format' => 'text/plain',
        'outformat' => 'turtle',
        'language' => 'en',
        'mode' => 'all'
      }
    end

    form_configurable :url
    form_configurable :body
    form_configurable :body_format, type: :array, values: ['text/plain', 'text/xml', 'text/n3', 'text/turtle', 'application/ld+json', 'application/n-triples', 'application/rdf+xml']
    form_configurable :outformat, type: :array, values: ['turtle', 'json-ld', 'n3', 'n-triples', 'rdf-xml', 'text/html']
    form_configurable :language, type: :array, values: ['en','de']
    form_configurable :analysis, type: :array, values: ['ner', 'dict', 'temp']
    form_configurable :mode, type: :array, values: ['all', 'spot', 'link']
    form_configurable :models, roles: :completable, cache_response: false
    common_nif_agent_fields

    def validate_options
      errors.add(:base, "url needs to be present") if options['url'].blank?
      errors.add(:base, "body needs to be present") if options['body'].blank?
      errors.add(:base, "models needs to be present") if options['models'].blank?
      validate_web_request_options!
    end

    def complete_models
      response = faraday.get(URI.join(interpolated['url'], '/api/e-nlp/listModels'), {analysis: interpolated['analysis']}, {'Accept' => 'application/json'})
      return [] if response.status != 200

      response.body.split("\n").map { |model| { text: model, id: model } }
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)

        nif_request!(mo, ['outformat', 'language', 'analysis', 'models', 'mode'], mo['url'], event: event)
      end
    end
  end
end
