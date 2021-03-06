# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      class EventClassRemapper
        def initialize(class_map)
          @class_map = class_map
        end

        def dump(item)
          item
        end

        def load(item)
          item.merge(event_type: class_map[item.fetch(:event_type)] || item.fetch(:event_type))
        end

        private
        attr_reader :class_map
      end
    end
  end
end
