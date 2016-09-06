module Agents
  class DktNerAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include NifApiAgentConcern

    default_schedule 'never'

    description <<-MD
      The `DktNerAgent` (DKT Named Entity Recognition) enriches text content with entities gathered from various datasets using the DKT API.

      The Agent accepts all configuration options of the `/e-nlp/namedEntityRecognition` endpoint as of march 2016, have a look at the [offical documentation](https://github.com/dkt-projekt/e-OpenNLP/tree/master-architecture-update#named-entity-recognition) if you need additional information

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `url` allows to customize the endpoint of the API when hosting the DKT services elswhere.

      `body` use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify the data to be send to the API.

      `body_format` specify the content-type of the data in `body`

      `outformat` requested RDF serialization format of the output

      `language` language of the source data

      `analysis`: The type of analysis to perform. Specify `ner` for performing NER based on a trained model. Specify `dict` to perform NER based on an uploaded dictionary. Specify `temp` to perform NER for temporal expressions.

      `link`: When set to `false` the look up of found entities on DBPedia to retrieve the corresponding DBPedia URI will be skipped.

      `models`: Specify a semicolon separated list of the models to be used for performing the analysis. The model has to be trained first.

      Current list of available models for `ner analysis:

          ner-de_aij-wikinerTrain_LOC
          ner-de_aij-wikinerTrain_ORG
          ner-de_aij-wikinerTrain_PER
          ner-wikinerEn_LOC
          ner-wikinerEn_ORG
          ner-wikinerEn_PER

      Current list of available models for `dict` analysis:

          testDummyDict_PER

      Current list of available models for `temp` analysis:

          germanDates (if language is `de`)
          englishDates (if language is `en`)
    MD

    def default_options
      {
        'url' => '',
        'body' => '{{ data }}',
        'body_format' => 'text/plain',
        'outformat' => 'turtle',
        'language' => 'en',
        'link' => 'true'
      }
    end

    form_configurable :url
    form_configurable :body
    form_configurable :body_format, type: :array, values: ['text/plain', 'text/xml', 'text/n3', 'text/turtle', 'application/ld+json', 'application/n-triples', 'application/rdf+xml']
    form_configurable :outformat, type: :array, values: ['turtle', 'json-ld', 'n3', 'n-triples', 'rdf-xml', 'text/html']
    form_configurable :language, type: :array, values: ['en','de']
    form_configurable :analysis, type: :array, values: ['ner', 'dict', 'temp']
    form_configurable :link, type: :boolean
    form_configurable :models

    def validate_options
      errors.add(:base, "url needs to be present") if options['url'].blank?
      errors.add(:base, "body needs to be present") if options['body'].blank?
      errors.add(:base, "models needs to be present") if options['models'].blank?
      validate_web_request_options!
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)
        mo['link'] = 'no' if mo.delete('link') == 'false'

        nif_request!(mo, ['outformat', 'language', 'analysis', 'models', 'link'], mo['url'])
      end
    end
  end
end
