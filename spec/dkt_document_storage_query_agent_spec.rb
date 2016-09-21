require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::DktDocumentStorageQueryAgent do
  before(:each) do
    @valid_options = Agents::DktDocumentStorageQueryAgent.new.default_options.merge('url' => 'http://some.endpoint.com', 'collection_name' => 'my-collection')
    @checker = Agents::DktDocumentStorageQueryAgent.new(:name => "somename", :options => @valid_options)
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

  describe "#check" do
    it "creates an event after a successfull request when mode is documents" do
      @checker.options['mode'] = 'documents'
      stub_request(:get, "http://some.endpoint.com/my-collection/documents").
         with(:headers => {'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'text/plain', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
         to_return(:status => 200, :body => '{"some": "json"}', :headers => {})
      expect { @checker.check }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload['body']).to eq({"some"=>"json"})
    end

    it "creates an event after a successfull request when mode is status" do
      @checker.options['mode'] = 'status'
      stub_request(:get, "http://some.endpoint.com/my-collection/status").
         with(:headers => {'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'text/plain', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
         to_return(:status => 200, :body => '{"some": "json"}', :headers => {})
      expect { @checker.check }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload['body']).to eq({"some"=>"json"})
    end
  end
end
