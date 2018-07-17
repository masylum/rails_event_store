RSpec.shared_examples :broker do |broker_klass|
  let(:event) { instance_double(::RubyEventStore::Event, type: 'EventType') }
  let(:serialized_event) { instance_double(::RubyEventStore::SerializedRecord)  }
  let(:handler) { HandlerClass.new }
  let(:subscriptions) { ::RubyEventStore::PubSub::Subscriptions.new }
  let(:dispatcher) { ::RubyEventStore::PubSub::Dispatcher.new }
  let(:broker) { broker_klass.new(subscriptions: subscriptions, dispatcher: dispatcher) }

  specify "no dispatch when no subscriptions" do
    expect(subscriptions).to receive(:all_for).with('EventType').and_return([])
    expect(dispatcher).not_to receive(:call)
    broker.call(event, serialized_event)
  end

  specify "calls subscription" do
    expect(subscriptions).to receive(:all_for).with('EventType').and_return([handler])
    expect(dispatcher).to receive(:call).with(handler, event, serialized_event)
    broker.call(event, serialized_event)
  end

  specify "calls subscribed class" do
    expect(subscriptions).to receive(:all_for).with('EventType').and_return([HandlerClass])
    expect(dispatcher).to receive(:call).with(HandlerClass, event, serialized_event)
    broker.call(event, serialized_event)
  end

  specify "calls all subscriptions" do
    expect(subscriptions).to receive(:all_for).with('EventType').and_return([handler, HandlerClass])
    expect(dispatcher).to receive(:call).with(handler, event, serialized_event)
    expect(dispatcher).to receive(:call).with(HandlerClass, event, serialized_event)
    broker.call(event, serialized_event)
  end

  specify 'raise error when no subscriber' do
    expect { broker.add_subscription(nil, [])}.to raise_error(RubyEventStore::SubscriberNotExist, "subscriber must be first argument or block")
    expect { broker.add_global_subscription(nil)}.to raise_error(RubyEventStore::SubscriberNotExist), "subscriber must be first argument or block"
    expect { broker.add_thread_subscription(nil, []).call}.to raise_error(RubyEventStore::SubscriberNotExist), "subscriber must be first argument or block"
    expect { broker.add_thread_global_subscription(nil).call}.to raise_error(RubyEventStore::SubscriberNotExist), "subscriber must be first argument or block"
  end

  specify "verify and add - local subscriptions" do
    expect(dispatcher).to receive(:verify).with(handler)
    expect(subscriptions).to receive(:add_subscription).with(handler, ['EventType'])
    broker.add_subscription(handler, ['EventType'])
  end

  specify "verify and add - global subscriptions" do
    expect(dispatcher).to receive(:verify).with(handler)
    expect(subscriptions).to receive(:add_global_subscription).with(handler)
    broker.add_global_subscription(handler)
  end

  specify "verify and add - thread local subscriptions" do
    expect(dispatcher).to receive(:verify).with(handler)
    expect(subscriptions).to receive(:add_thread_subscription).with(handler, ['EventType'])
    broker.add_thread_subscription(handler, ['EventType'])
  end

  specify "verify and add - thread global subscriptions" do
    expect(dispatcher).to receive(:verify).with(handler)
    expect(subscriptions).to receive(:add_thread_global_subscription).with(handler)
    broker.add_thread_global_subscription(handler)
  end

  private

  class HandlerClass
    @@received = nil
    def self.received
      @@received
    end
    def call(event)
      @@received = event
    end
  end
end