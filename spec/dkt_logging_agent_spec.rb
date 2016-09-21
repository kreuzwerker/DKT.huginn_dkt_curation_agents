require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::DktLoggingAgent do
  before(:each) do
    @valid_options = Agents::DktLoggingAgent.new.default_options.merge('url' => 'http://some.endpoint.com')
    @checker = Agents::DktLoggingAgent.new(:name => "somename", :options => @valid_options)
    @checker.user = users(:jane)
    @checker.save!
  end

  it_behaves_like WebRequestConcern
  it_behaves_like DktNifApiAgentConcern

  describe "validating" do
    before do
      expect(@checker).to be_valid
    end

    it "requires url to be present" do
      @checker.options['url'] = ''
      expect(@checker).not_to be_valid
    end

    it "requires value to be set" do
      @checker.options['value'] = ''
      expect(@checker).not_to be_valid
    end
  end

  describe "#receive" do
    before(:each) do
      @event = Event.new(payload: {value: "Hello from Huginn"})
    end

    it "creates an event after a successfull request" do
      stub_request(:post, "http://some.endpoint.com/?create=true&serviceType=database&value=Hello%20from%20Huginn").
         with(:headers => {'Accept-Encoding'=>'gzip,deflate', 'Content-Length'=>'0', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
         to_return(:status => 200, :body => "Interaction properly stored!!!.", :headers => {})
      expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload['body']).to eq('Interaction properly stored!!!.')
    end
  end
end
