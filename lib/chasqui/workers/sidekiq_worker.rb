module Chasqui
  class SidekiqWorker < Worker
    class << self

      def namespace
        Sidekiq.redis { |r| r.respond_to?(:namespace) ? r.namespace : nil }
      end

      def create(subscriber)
        find_or_build_worker(subscriber, Chasqui::SidekiqWorker).tap do |worker|
          worker.class_eval do
            include Sidekiq::Worker
            sidekiq_options queue: subscriber.queue
            @subscriber = subscriber

            def perform(event)
              Sidekiq.redis do |r|
                self.class.subscriber.perform r, event
              end
            end

            private

            def self.subscriber
              @subscriber
            end
          end
        end
      end

    end
  end
end
