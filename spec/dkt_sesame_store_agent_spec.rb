require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::DktSesameStoreAgent do
  before(:each) do
    @valid_options = Agents::DktSesameStoreAgent.new.default_options.merge('storageName' => 'teststorage', 'storagePath' => '/tmp', 'url' => 'http://some.endpoint.com')
    @checker = Agents::DktSesameStoreAgent.new(:name => "somename", :options => @valid_options)
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

    it "requires storagePath to be set" do
      @checker.options['storagePath'] = ''
      expect(@checker).not_to be_valid
    end
  end

  describe "#receive" do
    before(:each) do
      @event = Event.new(payload: {data: "Hello from Huginn"})
    end

    context 'with inputDataFormat body' do
      it "creates an event after a successfull request" do
        stub_request(:post, "http://some.endpoint.com/?inputDataFormat=body&inputDataMimeType=text/turtle&storageCreate=true&storageName=teststorage&storagePath=/tmp").
          with(:body => "Hello from Huginn",
               :headers => {'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'text/turtle', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
          to_return(:status => 200, :body => "DATA", :headers => {})
        expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
        event = Event.last
        expect(event.payload['body']).to eq('DATA')
      end
    end

    context 'with inputDataFormat triple' do
      it "creates an event after a successfull request" do
        @checker.options['inputDataFormat'] = 'triple'
        @checker.options['subject'] = 'ttp://de.dkt.sesame/ontology/doc1'
        @checker.options['predicate'] = 'ttp://de.dkt.sesame/ontology/doc2'
        @checker.options['object'] = 'object'
        stub_request(:post, "http://some.endpoint.com/?inputDataFormat=triple&inputDataMimeType=text/turtle&object=object&predicate=ttp://de.dkt.sesame/ontology/doc2&storageCreate=true&storageName=teststorage&storagePath=/tmp&subject=ttp://de.dkt.sesame/ontology/doc1").
          with(:headers => {'Accept-Encoding'=>'gzip,deflate', 'Content-Length'=>'0', 'Content-Type'=>'', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
          to_return(:status => 200, :body => "DATA", :headers => {})
        expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
        event = Event.last
        expect(event.payload['body']).to eq('DATA')
      end
    end
  end
end
