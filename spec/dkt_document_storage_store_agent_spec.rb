require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::DktDocumentStorageStoreAgent do
  before(:each) do
    @valid_options = Agents::DktDocumentStorageStoreAgent.new.default_options.merge('url' => 'http://some.endpoint.com', 'fileName' => 'test.txt', 'collection_name' => 'my-collection')
    @checker = Agents::DktDocumentStorageStoreAgent.new(:name => "somename", :options => @valid_options)
    @checker.user = users(:jane)
    @checker.save!
  end

  it_behaves_like WebRequestConcern
  it_behaves_like DktNifApiAgentConcern

  describe "validating" do
    before do
      expect(@checker).to be_valid
    end

    it "requires url to be set" do
      @checker.options['url'] = ''
      expect(@checker).not_to be_valid
    end

    it "url must not end with a slash" do
      @checker.options['url'] = 'test/'
      expect(@checker).not_to be_valid
    end
  end

  describe "#receive" do
    it "creates an event after a successfull request" do
      event = Event.new(payload: {data: "Hello from Huginn"})
      stub_request(:post, "http://some.endpoint.com/my-collection?fileName=test.txt").
        with(:body => "Hello from Huginn",
             :headers => {'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'text/plain', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
        to_return(:status => 200, :body => "DATA", :headers => {})
      expect { @checker.receive([event]) }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload['body']).to eq('DATA')
    end

    it 'handles a incoming file pointer' do
      stub_request(:post, "http://some.endpoint.com/my-collection?fileName=test.txt").
        with(:body => "testdata",
             :headers => {'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'text/plain', 'Transfer-Encoding'=>'chunked', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
        to_return(:status => 200, :body => "DATA", :headers => {})
      event = Event.new(payload: {file_pointer: {agent_id: 111, file: 'test'}})
      io_mock = mock()
      mock(@checker).get_io(event) { StringIO.new("testdata") }

      expect { @checker.receive([event]) }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload['body']).to eq('DATA')
    end
  end
end
