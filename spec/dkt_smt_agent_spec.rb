require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::DktSmtAgent do
  before(:each) do
    @valid_options = Agents::DktSmtAgent.new.default_options.merge('url' => 'http://some.endpoint.com')
    @checker = Agents::DktSmtAgent.new(:name => "somename", :options => @valid_options)
    @checker.user = users(:jane)
    @checker.save!
  end

  it_behaves_like WebRequestConcern
  it_behaves_like DktNifApiAgentConcern

  describe "validating" do
    before do
      expect(@checker).to be_valid
    end

    it "requires body to be present" do
      @checker.options['body'] = ''
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
    end

    it "creates an event after a successfull request" do
         stub_request(:post, "http://some.endpoint.com/?source-lang=en&target-lang=de").
         with(:body => "Hello from Huginn",
              :headers => {'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'text/plain', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
         to_return(:status => 200, :body => "DATA", :headers => {})
      expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload['body']).to eq('DATA')
    end
  end
end
