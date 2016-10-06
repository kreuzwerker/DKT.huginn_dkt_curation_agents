module Agents
  class DktClusteringAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include DktNifApiAgentConcern
    include FileHandling

    consumes_file_pointer!

    default_schedule 'never'

    description do
      <<-MD
        The `DktClusteringAgent` clusters the input document collection. The document collection first has to be converted to a set of vectors.

        The Agent expects the input in this particular format and then proceeds to find clusters in this input data. The output contains information on the number of clusters found and specific values for the found clusters.

        The Agent accepts all configuration options of the `/e-clustering/generateClusters` endpoint as of september 2016, have a look at the [offical documentation](https://github.com/dkt-projekt/e-Clustering#e-clustering-1) if you need additional information

        All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

        `url` allows to customize the endpoint of the API when hosting the DKT services elswhere.

        `body` use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify the input .arff file. See http://www.cs.waikato.ac.nz/ml/weka/arff.html for an explanation of this format.

        `language` language of the source data

        `algorithm`: the algorithm to be used during clustering. Currently EM and Kmeans are supported.

        #{self.class.common_nif_agent_fields_description}

        **When receiving a file pointer:**

        `body` will be ignored and the contents of the received file will be send instead.

        #{receiving_file_handling_agent_description}
      MD
    end

    def default_options
      {
        'url' => '',
        'body' => '{{ data }}',
        'language' => 'en',
        'algorithm' => 'EM'
      }
    end

    form_configurable :url
    form_configurable :body, type: :text
    form_configurable :language, type: :array, values: ['en','de']
    form_configurable :algorithm, type: :array, values: ['em', 'kmeans']
    common_nif_agent_fields

    def validate_options
      errors.add(:base, "url needs to be present") if options['url'].blank?
      errors.add(:base, "body needs to be present") if options['body'].blank?
      validate_web_request_options!
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event).merge('body_format' => 'text/plain')

        if io = get_io(event)
          mo['body'] = io
        end

        nif_request!(mo, ['language', 'algorithm'], mo['url'], parse_response: :json, event: event)
      end
    end
  end
end
