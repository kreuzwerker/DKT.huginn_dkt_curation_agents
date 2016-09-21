require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::DktSesameRetrieveAgent do
  before(:each) do
    @valid_options = Agents::DktSesameRetrieveAgent.new.default_options.merge('storageName' => 'teststorage', 'inputDataFormat' => 'sparql', 'url' => 'http://some.endpoint.com', 'outformat' => 'text/turtle')
    @checker = Agents::DktSesameRetrieveAgent.new(:name => "somename", :options => @valid_options)
    @checker.user = users(:jane)
    @checker.save!
  end

  it_behaves_like WebRequestConcern
  it_behaves_like DktNifApiAgentConcern

  describe "validating" do
    before do
      expect(@checker).to be_valid
    end

    it "requires storageName to be present" do
      @checker.options['storageName'] = ''
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

    context 'with inputDataFormat sparql' do
      it "creates an event after a successfull request" do
        stub_request(:post, "http://some.endpoint.com/?input=Hello%20from%20Huginn&inputDataFormat=sparql&storageName=teststorage").
          with(:headers => {'Accept-Encoding'=>'gzip,deflate', 'Content-Length'=>'0', 'Content-Type'=>'', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
          to_return(:status => 200, :body => "DATA", :headers => {})
        expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
        event = Event.last
        expect(event.payload['body']).to eq('DATA')
      end
    end

    context 'with inputDataFormat triple' do
      it "creates an event after a successfull request" do
        @checker.options['inputDataFormat'] = 'triple'
        @checker.options['object'] = 'http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#Context'
        stub_request(:post, "http://some.endpoint.com/?inputDataFormat=triple&object=http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core%23Context&outformat=text/turtle&storageName=teststorage").
          with(:headers => {'Accept-Encoding'=>'gzip,deflate', 'Content-Length'=>'0', 'Content-Type'=>'', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
          to_return(:status => 200, :body => "DATA", :headers => {})
        expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
        event = Event.last
        expect(event.payload['body']).to eq('DATA')
      end
    end
  end
end
