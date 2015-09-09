require 'aws-sdk'
require 'net/http'

module AWSAttachVolume
  class Main
    include Methadone::CLILogging
    include Methadone::ExitNow

    def initialize(options={})
      client= Aws::EC2::Client.new(region: options[:region])
      @resource = Aws::EC2::Resource.new(client: client)
      @volume = @resource.volume(options[:volume_id])
      @instance_id = options[:instance_id]
      @device = options[:device]
      @move = options[:move]

      if @instance_id.nil? || @instance_id == ''
        @instance_id = instance_id
      end

      @instance_az = instance_az
    end

    def run()

      need_move = true if @volume.availability_zone != @instance_az

      unless @volume.state == 'available'
        fatal "Volume not in available state: #{@volume.state}"
        exit_now!(-1)
      end

      unless !need_move || (need_move && @move)
        fatal "Volume not in the same Availability Zone as the instance and --move not set.  Instance: #{@instance_az} Volume: #{@volume.availability_zone}"
        exit_now!(-1)
      end

      if need_move && @move
        info "Volume not in the same Availability Zone, moving."
        move_volume
      end

      info "Attaching volume #{@volume_id} to instance #{@instance_id} as device #{@device}."
      @volume.attach_to_instance({
                                    instance_id: @instance_id,
                                    device: @device
                                })
      while(!File.exist?(@device))
        count = 0
        count += 1
        if count >= 60
          fatal "Mount timed out."
          exit_now!(-1)
        end
      end
    end

    def validate()

    end

    def instance_id()
      metadata_endpoint = 'http://169.254.169.254/latest/meta-data/'
      instance_id = Net::HTTP.get( URI.parse( metadata_endpoint + 'instance-id' ) )
      info "Instance ID: #{instance_id}"
      return instance_id
    end

    def instance_az()
      metadata_endpoint = 'http://169.254.169.254/latest/meta-data/'
      availability_zone = Net::HTTP.get( URI.parse( metadata_endpoint + 'placement/availability-zone' ) )
      info "Instance AZ: #{availability_zone}"
      return availability_zone
    end

    def hash_tags(hash)
      tags = []
      hash.each do |k,v|
        tags << { key: k, value: v }
      end
    end

    def move_volume()
      # Snapshot volume and restore to current az.  Delete old volume & snapshot.
      info "Creating snapshot."
      snapshot = @volume.create_snapshot({
                                             description: 'AWSAttachVolume temp for moving volume'
                                         })
      snapshot.wait_until_completed
      info "Snapshot complete."
      unless @volume.tags.nil? || @volume.tags == ''
        info "Tagging snapshot."
        snapshot.create_tags({
                                 tags: @volume.tags
                             })
      end
      info "Creating new volume in #{@instance_az}"
      new_volume = @resource.create_volume({
                                    snapshot_id: snapshot.id,
                                    availability_zone: @instance_az,
                                    volume_type: 'gp2'
                                  })
      @resource.client.wait_until(:volume_available, {volume_ids: [new_volume.id]})
      info "New volume created: #{new_volume.id}"
      unless @volume.tags.nil? || @volume.tags == ''
        info "Tagging volume."
        new_volume.create_tags({
                                   tags: @volume.tags
                               })
      end
      info "Deleting old volume: #{@volume.id}"
      @volume.delete
      @resource.client.wait_until(:volume_deleted, {volume_ids: [@volume.id]})
      info "Volume deleted."
      @volume = new_volume
      info "Deleting snapshot: #{snapshot.id}"
      snapshot.delete
    end
  end
end

