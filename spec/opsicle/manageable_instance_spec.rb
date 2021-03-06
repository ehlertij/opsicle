require "spec_helper"
require "opsicle"
require 'gli'
require "opsicle/user_profile"

module Opsicle
  describe ManageableInstance do
    before do
      @instance = double('instance1', :hostname => 'example-hostname-01', :status => 'active',
                                       :ami_id => 'ami_id', :instance_type => 'instance_type',
                                       :agent_version => 'agent_version', :stack_id => 1234567890,
                                       :layer_ids => [12345, 67890], :auto_scaling_type => 'auto_scaling_type',
                                       :os => 'os', :ssh_key_name => 'ssh_key_name',
                                       :availability_zone => 'availability_zone', :virtualization_type => 'virtualization_type',
                                       :subnet_id => 'subnet_id', :architecture => 'architecture',
                                       :root_device_type => 'root_device_type', :install_updates_on_boot => 'install_updates_on_boot',
                                       :ebs_optimized => 'ebs_optimized', :tenancy => 'tenancy', :instance_id => 'some-id')
      @layer = double('layer1', :name => 'layer-1', :layer_id => 12345, :instances => [@instance], :ami_id => nil, :agent_version => nil)
      allow(@layer).to receive(:ami_id=)
      allow(@layer).to receive(:ami_id)
      allow(@layer).to receive(:agent_version=)
      allow(@layer).to receive(:agent_version)
      allow(@layer).to receive(:add_new_instance)
      allow(@layer).to receive(:subnet_id=)
      allow(@layer).to receive(:subnet_id)
      @new_instance = double('new_instance', :instance_id => 1029384756)
      @opsworks = double('opsworks', :create_instance => @new_instance)
      @ec2 = double('ec2')
      @stack = double('stack')
      @agent_version_1 = double('agent_version', :version => '3434-20160316181345')
      @agent_version_2 = double('agent_version', :version => '3435-20160406115841')
      @agent_version_3 = double('agent_version', :version => '3436-20160418214624')
      @agent_versions = double('agent_versions', :agent_versions => [@agent_version_1, @agent_version_2, @agent_version_3])
      allow(@opsworks).to receive(:describe_agent_versions).with({:stack_id=>1234567890}).and_return(@agent_versions)
      tag1 = double('tag', :value => 'Subnet', :key => 'Name')
      @tags = [tag1]
      @subnet1 = double('subnet', :vpc_id => 'vpc-123456', :subnet_id => 'subnet-123456', :tags => @tags, :availability_zone => 'us-east-1b')
      @subnet2 = double('subnet', :vpc_id => 'vpc-123456', :subnet_id => 'subnet-789123', :tags => @tags, :availability_zone => 'us-east-1b')
      @subnet3 = double('subnet', :vpc_id => 'vpc-123456', :subnet_id => 'subnet-456789', :tags => @tags, :availability_zone => 'us-east-1b')
      @subnets = double('subnets', :subnets => [@subnet1, @subnet2, @subnet3])
      allow(@stack).to receive(:vpc_id).and_return('vpc-123456')
      @instances = double('instances', :instances => [@instance])
      allow(@ec2).to receive(:describe_subnets).and_return(@subnets)
      allow(@opsworks).to receive(:describe_instances).with({:stack_id=>1234567890}).and_return(@instances)
      @current_subnet = double('subnet', :tags => @tags, :availability_zone => 'us-east-1b')
      allow(Aws::EC2::Subnet).to receive(:new).and_return(@current_subnet)
      @cli = double('cli', :ask => 2)
    end

    context "#make_new_hostname" do
      it "should make a unique incremented hostname" do
        instance = ManageableInstance.new(@instance, @layer, @stack, @opsworks, @ec2, @cli)
        instance1 = double('instance', :hostname => 'example-hostname-01')
        instance2 = double('instance', :hostname => 'example-hostname-02')
        allow(@layer).to receive(:instances).and_return([instance1, instance2])
        expect(instance.make_new_hostname).to eq('example-hostname-03')
      end

      it "should make a unique incremented hostname" do
        instance = ManageableInstance.new(@instance, @layer, @stack, @opsworks, @ec2, @cli)
        instance1 = double('instance', :hostname => 'example-hostname-01')
        instance2 = double('instance', :hostname => 'example-hostname-02')
        instance3 = double('instance', :hostname => 'example-hostname-03')
        instance4 = double('instance', :hostname => 'example-hostname-04')
        allow(@layer).to receive(:instances).and_return([instance1, instance2, instance3, instance4])
        expect(instance.make_new_hostname).to eq('example-hostname-05')
      end
    end

    context "#increment_hostname" do
      it "should increment the hostname" do
        instance = ManageableInstance.new(@instance, @layer, @stack, @opsworks, @ec2, @cli)
        expect(instance).to receive(:hostname_unique?).and_return('example-hostname-03')
        allow(@opsworks).to receive(:describe_agent_version).with({})
        expect(instance.increment_hostname).to eq('example-hostname-01')
      end
    end

    context "#clone" do
      it "should grab instances and make new hostname" do
        instance = ManageableInstance.new(@instance, @layer, @stack, @opsworks, @ec2, @cli)
        expect(instance).to receive(:make_new_hostname).and_return('example-hostname-03')
        instance.clone({})
      end

      it "should get information from old instance" do
        instance = ManageableInstance.new(@instance, @layer, @stack, @opsworks, @ec2, @cli)
        expect(instance).to receive(:verify_ami_id)
        expect(instance).to receive(:verify_agent_version)
        expect(instance).to receive(:verify_instance_type)
        expect(instance).to receive(:verify_subnet_id)
        instance.clone({})
      end

      it "should create new instance" do
        instance = ManageableInstance.new(@instance, @layer, @stack, @opsworks, @ec2, @cli)
        expect(instance).to receive(:create_new_instance)
        instance.clone({})
      end

      it "should start new instance" do
        instance = ManageableInstance.new(@instance, @layer, @stack, @opsworks, @ec2, @cli)
        allow(instance).to receive(:ask_to_start_instance).and_return(true)
        expect(instance).to receive(:start_new_instance)
        instance.clone({})
      end
    end

    context '#verify_agent_version' do
      it "should check the agent version and ask if the user wants a new agent version" do
        @cli = double('cli', :ask => 1)
        instance = ManageableInstance.new(@instance, @layer, @stack, @opsworks, @ec2, @cli)
        allow(@layer).to receive(:agent_version).and_return(nil)
        allow_any_instance_of(HighLine).to receive(:ask).with("Do you wish to override this version? By overriding, you are choosing to override the current agent version for all instances you are cloning.\n1) Yes\n2) No", Integer).and_return(1)
        expect(instance).to receive(:ask_for_possible_options)
        instance.verify_agent_version
      end

      it "should see if the layer already has overwritten the agent version" do
        instance = ManageableInstance.new(@instance, @layer, @stack, @opsworks, @ec2, @cli)
        expect(@layer).to receive(:agent_version)
        instance.verify_agent_version
      end
    end

    context '#verify_subnet_id' do
      it "should check the subnet id and ask if the user wants a new subnet id" do
        @cli = double('cli', :ask => 1)
        instance = ManageableInstance.new(@instance, @layer, @stack, @opsworks, @ec2, @cli)
        allow(@layer).to receive(:subnet_id).and_return(nil)
        allow_any_instance_of(HighLine).to receive(:ask).with("Do you wish to override this id? By overriding, you are choosing to override the current agent version for all instances you are cloning.\n1) Yes\n2) No", Integer).and_return(1)
        expect(instance).to receive(:ask_for_possible_options)
        instance.verify_subnet_id
      end

      it "should see if the layer already has overwritten the subnet id" do
        instance = ManageableInstance.new(@instance, @layer, @stack, @opsworks, @ec2, @cli)
        expect(@layer).to receive(:subnet_id)
        instance.verify_subnet_id
      end
    end

    context '#verify_ami_id' do
      it "should check the ami id and ask if the user wants a new ami" do
        @cli = double('cli', :ask => 1)
        instance = ManageableInstance.new(@instance, @layer, @stack, @opsworks, @ec2, @cli)
        allow(@layer).to receive(:ami_id).and_return(nil)
        allow_any_instance_of(HighLine).to receive(:ask).with("Do you wish to override this AMI? By overriding, you are choosing to override the current AMI for all instances you are cloning.\n1) Yes\n2) No", Integer).and_return(1)
        expect(@cli).to receive(:ask)
        expect(instance).to receive(:ask_for_possible_options)
        instance.verify_ami_id
      end

      it "should see if the layer already has overwritten the ami id" do
        instance = ManageableInstance.new(@instance, @layer, @stack, @opsworks, @ec2, @cli)
        expect(@layer).to receive(:ami_id)
        instance.verify_ami_id
      end
    end

    context '#verify_instance_type' do
      it "should check the agent version and ask if the user wants a new agent version" do
        @cli = double('cli', :ask => 1)
        instance = ManageableInstance.new(@instance, @layer, @stack, @opsworks, @ec2, @cli)
        allow(@layer).to receive(:ami_id).and_return(nil)
        allow_any_instance_of(HighLine).to receive(:ask).with("Do you wish to override this instance type?\n1) Yes\n2) No", Integer).and_return(1)
        expect(@cli).to receive(:ask).twice
        instance.verify_instance_type
      end
    end

    context "#create_new_instance" do
      it "should create an instance" do
        instance = ManageableInstance.new(@instance, @layer, @stack, @opsworks, @ec2, @cli)
        expect(@opsworks).to receive(:create_instance)
        instance.create_new_instance('hostname', 'type', 'ami', 'agent_version', 'subnet_id')
      end

      it "should take information from old instance" do
        instance = ManageableInstance.new(@instance, @layer, @stack, @opsworks, @ec2, @cli)
        expect(instance).to receive(:stack_id)
        expect(instance).to receive(:layer_ids)
        expect(instance).to receive(:auto_scaling_type)
        expect(instance).to receive(:os)
        expect(instance).to receive(:ssh_key_name)
        expect(instance).to receive(:virtualization_type)
        instance.create_new_instance('hostname', 'type', 'ami', 'agent_version', 'subnet_id')
      end
    end
  end
end
