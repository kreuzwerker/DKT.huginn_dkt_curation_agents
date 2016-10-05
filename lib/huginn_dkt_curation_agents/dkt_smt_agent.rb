module Agents
  class DktSmtAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include DktNifApiAgentConcern

    default_schedule 'never'

    description <<-MD
      The `DktSmtAgent` performs Statistical Machine Translation using the DKT API.

      The Agent accepts all configuration options of the `/e-emt` endpoint as of september 2016, have a look at the [offical documentation](https://github.com/dkt-projekt/e-SMT) if you need additional information

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `url` allows to customize the endpoint of the API when hosting the DKT services elswhere.

      `body` use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify the data to be send to the API.

      `body_format` specify the content-type of the data in `body`

      `outformat` requested RDF serialization format of the output

      `source-lang`: The language of the input text.

      `target-lang`: The language of the output text.

      Note, the current implementation translates in the following four directions:

          German to English
          English to German
          Spanish to English
          English to Spanish

      `merge` set to true to retain the received payload and update it with the extracted result
    MD

    def default_options
      {
        'url' => '',
        'body' => '{{ data }}',
        'body_format' => 'text/plain',
        'source_lang' => 'en',
        'target_lang' => 'de'
      }
    end

    form_configurable :url
    form_configurable :body
    form_configurable :body_format, type: :array, values: ['text/plain', 'text/xml', 'text/n3', 'text/turtle', 'application/ld+json', 'application/n-triples', 'application/rdf+xml']
    form_configurable :outformat, type: :array, values: ['turtle', 'json-ld', 'n3', 'n-triples', 'rdf-xml', 'text/html']
    form_configurable :source_lang, type: :array, values: ['en','de', 'es']
    form_configurable :target_lang, type: :array, values: ['en','de', 'es']
    form_configurable :merge, type: :boolean

    def validate_options
      errors.add(:base, "url needs to be present") if options['url'].blank?
      errors.add(:base, "body needs to be present") if options['body'].blank?
      validate_web_request_options!
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)

        nif_request!(mo, ['target_lang', 'source_lang'], mo['url'], event: event)
      end
    end
  end
end
