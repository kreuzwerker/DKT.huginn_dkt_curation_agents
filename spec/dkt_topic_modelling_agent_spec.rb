require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::DktTopicModellingAgent do
  before(:each) do
    @valid_options = Agents::DktTopicModellingAgent.new.default_options.merge('url' => 'http://some.endpoint.com')
    @checker = Agents::DktTopicModellingAgent.new(:name => "somename", :options => @valid_options)
    @checker.user = users(:jane)
    @checker.save!
  end

  it_behaves_like WebRequestConcern
  it_behaves_like NifApiAgentConcern

  describe "validating" do
    before do
      expect(@checker).to be_valid
    end

    it "requires input to be present" do
      @checker.options['input'] = ''
      expect(@checker).not_to be_valid
    end

    it "requires url to be set" do
      @checker.options['url'] = ''
      expect(@checker).not_to be_valid
    end
  end

  describe "#receive" do
    before(:each) do
      @event = Event.new(payload: {data: "Hello from Huginn"})
      @checker.options['language'] = 'en'
    end

    it "creates an event after a successfull request" do
      stub_request(:post, "http://some.endpoint.com?informat=text/plain&input=Hello%20from%20Huginn&language=en&modelName=3pc&outformat=turtle").
        with(:headers => {'Accept-Encoding'=>'gzip,deflate', 'Content-Length'=>'0', 'Content-Type'=>'', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
        to_return(:status => 200, :body => "DATA", :headers => {})
      expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload['body']).to eq('DATA')
    end
  end
end
