require 'aws-sdk'
require 'net/http'

module AWSAttachVolume
  class Main
    include Methadone::CLILogging

    def initialize(options={})
      @client = Aws::EC2::Client.new(region: options[:region])
      @volume_id = options[:volume_id]
      @instance_id = options[:instance_id]
      @device = options[:device]

      if @instance_id.nil? || @instance_id == ''
        @instance_id = instance_id()
      end

      @instance_az = instance_az()
    end

    def run()
      volume_available(@client, @volume_id, @instance_az)

      resp = client.attach_volume({
                                      volume_id: [@volume_id],
                                      instance_id: @instance_id,
                                      device: @device
                                  })
      info "Attaching volume #{@volume_id} to instance #{@instance_id}"
      while(!File.exist?(@device))
        count += 1
        if count >= 60
          fatal "Mount timed out."
          exit_now!("-1")
        end
      end
    end

    def instance_id()
      metadata_endpoint = 'http://169.254.169.254/latest/meta-data/'
      instance_id = Net::HTTP.get( URI.parse( metadata_endpoint + 'instance-id' ) )
      info "Instance ID: #{instance_id}"
      return instance_id
    end

    def instance_az()
      metadata_endpoint = 'http://169.254.169.254/latest/meta-data/'
      availability_zone = Net::HTTP.get( URI.parse( metadata_endpoint + 'availability_zone' ) )
      info "Instance AZ: #{availability_zone}"
      return availability_zone
    end

    def volume_available(client, volume_id, az)
      resp = client.describe_volumes({
                                         volume_ids: [volume_id],
                                         max_results: 1
                                     })
      volume_az = resp.volumes[0].availability_zone
      if volume_az != az
        fatal "Volume and instance not in the same Availability Zone. Volume: #{volume_az} Instance: #{az}"
        exit_now!("-1")
      end
      state = resp.volumes[0].attachments[0].state
      if state != 'detached'
        fatal "Volume not detached! Current state: #{state}"
        exit_now!("-1")
      end
      return true
    end
  end
end

