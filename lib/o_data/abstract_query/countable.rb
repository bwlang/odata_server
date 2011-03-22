module OData
  module AbstractQuery
    module Countable
      def self.included(base)
        base.send(:extend, SingletonMethods)
        base.send(:include, InstanceMethods)
      end
      
      module SingletonMethods
        def countable?
          false
        end
      end
      
      module InstanceMethods
        def countable?
          self.class.countable?
        end
      end
    end
  end
end
