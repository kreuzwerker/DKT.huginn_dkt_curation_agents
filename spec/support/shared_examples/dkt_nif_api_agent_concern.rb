require 'rails_helper'

shared_examples_for DktNifApiAgentConcern do
  it "event description does not throw an exception" do
    expect(@checker.event_description).to include('body')
  end

  context '#working' do
    it 'is not working without having received an event' do
      expect(@checker).not_to be_working
    end

    it 'is working after receiving an event without error' do
      @checker.last_receive_at = Time.now
      expect(@checker).to be_working
    end
  end

  it "check calls receive with an empty event" do
    event = Event.new
    mock(Event).new { event }
    mock(@checker).receive([event])
    @checker.check
  end

  context '#merge' do
    let(:event) { Event.new(payload: {some: 'data'}) }

    before do
      stub_request(:any, //).
         to_return(:status => 200, :body => '{"some": "json"}', :headers => {})
    end

    it 'does not merge the received event into the result per default' do
      expect { @checker.receive([event]) }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload[:some]).to be_nil
    end

    it 'merges the results with the received event when merge is set to true' do
      @checker.options['merge'] = "true"
      expect { @checker.receive([event]) }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload[:some]).to eq('data')
    end
  end
end
