# frozen_string_literal: true

module BillableMetrics
  module Aggregations
    class BaseService < ::BaseService
      def initialize(billable_metric:, subscription:, group: nil, event: nil)
        super(nil)
        @billable_metric = billable_metric
        @subscription = subscription
        @group = group
        @event = event
      end

      def aggregate(from_date:, to_date:, options: {})
        raise(NotImplementedError)
      end

      protected

      attr_accessor :billable_metric, :subscription, :group, :event

      delegate :customer, to: :subscription

      def events_scope(from_datetime:, to_datetime:)
        events = subscription.events
          .from_datetime(from_datetime)
          .to_datetime(to_datetime)
          .where(code: billable_metric.code)
        return events unless group

        events = events.where('properties @> ?', { group.key.to_s => group.value }.to_json)
        return events unless group.parent

        events.where('properties @> ?', { group.parent.key.to_s => group.parent.value }.to_json)
      end

      def sanitized_name(property)
        ActiveRecord::Base.sanitize_sql_for_conditions(
          ['events.properties->>?', property],
        )
      end

      def sanitized_field_name
        sanitized_name(billable_metric.field_name)
      end
    end
  end
end
