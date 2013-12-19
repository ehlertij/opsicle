require 'opsicle/config'

module Opsicle
  class Client
    attr_reader :aws_client
    attr_reader :config

    def initialize(environment)
      @config = Config.new(environment)
      @config.configure_aws!
      @aws_client = AWS::OpsWorks.new.client
    end

    def run_command(command, options={})
      aws_client.create_deployment(command_options(command, options))
    end

    def api_call(command, options={})
      aws_client.send(command, options)
    end

    def command_options(command, options={})
      config.opsworks_config.merge(options).merge({ command: { name: command } })
    end
    private :command_options

  end
end
