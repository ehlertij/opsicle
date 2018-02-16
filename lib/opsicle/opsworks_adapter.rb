module Opsicle
  class OpsworksAdapter
    attr_reader :client

    def initialize(client)
      @client = client.opsworks
    end

    def get_layers(stack_id)
      client.describe_layers(stack_id: stack_id).layers
    end

    def start_instance(instance_id)
      client.start_instance(instance_id: instance_id)
    end
  end
end
