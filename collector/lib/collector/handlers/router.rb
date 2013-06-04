# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class Router < Handler
      register Components::ROUTER_COMPONENT

      def process(context)
        varz = context.varz

        return unless varz["tags"]
        varz["tags"].each do |key, values|
          values.each do |value, metrics|
            if key == "component" && value.start_with?("dea-")

              # Sorry for this gem. We want to grab the DEA's number instead of its guid
              # i.e. dea-1-deadbeef should be parsed out to 1. The dea- is there by convention
              dea_id = value.split("-")[1]
              tags = {:component => "dea", :dea_index => dea_id }
            else
              tags = {key => value}
            end

            send_metric("router.requests", metrics["requests"], context, tags)
            send_latency_metric("router.latency.1m", metrics["latency"], context, tags)
            ["2xx", "3xx", "4xx", "5xx", "xxx"].each do |status_code|
              send_metric("router.responses", metrics["responses_#{status_code}"], context, tags.merge("status" => status_code))
            end
          end
        end

        send_metric("router.total_requests", varz["requests"], context)
        send_metric("router.total_routes", varz["urls"], context)
      end
    end
  end
end
