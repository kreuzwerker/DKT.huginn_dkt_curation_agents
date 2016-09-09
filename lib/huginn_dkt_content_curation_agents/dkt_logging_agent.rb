module Agents
  class DktLoggingAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include DktNifApiAgentConcern

    default_schedule 'never'

    description <<-MD
      The `DktLoggingAgent` registers information related to user actions using the DKT API.

      The Agent accepts all configuration options of the `/e-logging` endpoint as of september 2016, have a look at the [offical documentation](https://github.com/dkt-projekt/e-Logging) if you need additional information.

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `url` allows to customize the endpoint of the API when hosting the DKT services elswhere.

      `serviceType`: defines if the logging information is stored in a file (`file`) or in a database (`database`).

      `loggingServiceName`: is only needed for `file` serviceType. In the case of `database`, this field is ignored.

      `create`: defines if the logging service has to be created in case it does not exists. It is only needed for `file` serviceType. In the case of `database`, this field is ignored.

      `user`: the user that generates the logging information.

      `interactionType`: type of the interaction. Currently there are five possible values: feedback (`FEEDBACK`), usage (`USAGE`), RELEVANCE (`RELEVANCE`), ERROR (`ERROR`) and  general (`GENERAL`).

      `objectId`: unique identification of the object that receives the relevance judgment.

      `relevanceValue`: the value of the relevance judgment. There are five possible values: `veryirrelevant`, `irrelevant`, `neutrum`, `relevant` and `veryrelevant`.

      `value`: a specific value associated with the interaction.

      `errorId`: unique identification of the error.

      `errorType`: the type of the error has not been defined for now, but it can be something like: BadRequestException, EmptyInputArgument, etc.

      `additionalInformation`: additional text associated with the interaction.
    MD

    def default_options
      {
        'url' => '',
        'serviceType' => 'database',
        'create' => 'true',
        'value' => '{{ value }}'
      }
    end

    form_configurable :url
    form_configurable :serviceType, type: :array, values: ['database', 'file']
    form_configurable :create, type: :boolean
    form_configurable :user
    form_configurable :interactionType, type: :array, values: ['FEEDBACK', 'USAGE', 'RELEVANCE', 'ERROR', 'GENERAL']
    form_configurable :objectId
    form_configurable :relevanceValue, type: :array, values: ['veryirrelevant', 'irrelevant', 'neutrum', 'relevant', 'veryrelevant']
    form_configurable :value
    form_configurable :errorId
    form_configurable :errorType
    form_configurable :additionalInformation

    def validate_options
      errors.add(:base, "url needs to be present") if options['url'].blank?
      errors.add(:base, "value needs to be present") if options['value'].blank?
      validate_web_request_options!
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)

        response = faraday.run_request(:post, mo['url'], nil, {}) do |request|
          request.params.update(mo.except('url'))
        end

        create_event payload: { body: response.body, headers: response.headers, status: response.status }
      end
    end
  end
end
