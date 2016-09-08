require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::DktNerAgent do
  before(:each) do
    @valid_options = Agents::DktNerAgent.new.default_options.merge('models' => 'testmodel', 'url' => 'http://some.endpoint.com')
    @checker = Agents::DktNerAgent.new(:name => "somename", :options => @valid_options)
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

    it "requires models to be set" do
      @checker.options['models'] = ''
      expect(@checker).not_to be_valid
    end
  end

  describe '#complete_models' do
    it 'fetches the availble models for the configured mode' do
       stub_request(:get, "http://some.endpoint.com/api/e-nlp/listModels?analysis=ner").
         with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip,deflate', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn', 'X-Auth-Token'=>''}).
         to_return(:status => 200, :body => "model1\nmodel2", :headers => {})
      @checker.options['analysis'] = 'ner'
      expect(@checker.complete_models).to eq([{:text=>"model1", :id=>"model1"}, {:text=>"model2", :id=>"model2"}])
    end
  end

  describe "#receive" do
    before(:each) do
      @event = Event.new(payload: {data: "Hello from Huginn"})
      @checker.options['models'] = 'testmodel'
      @checker.options['language'] = 'en'
      @checker.options['analysis'] = 'temp'
      @checker.options['mode'] = 'all'
    end

    it "creates an event after a successfull request" do
      stub_request(:post, "http://some.endpoint.com/?analysis=temp&language=en&mode=all&models=testmodel&outformat=turtle").
         with(:body => "Hello from Huginn",
              :headers => {'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'text/plain', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
         to_return(:status => 200, :body => "DATA", :headers => {})
      expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload['body']).to eq('DATA')
    end
  end
end
