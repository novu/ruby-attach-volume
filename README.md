# AWSAttachVolume

Use this gem to attach an existing volume to an instance.  It will verify the volume is in the available state and the same region before attaching.  Instance will need IAM permissions to describe the volume and attach the volume.  If using move, the instance will also need to describe snapshots, create & delete both volumes and snapshots.  Recommended to use conditionals to lock this access down using tags or another ec2 key.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'AWSAttachVolume'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install AWSAttachVolume

## Usage

```
Usage: awsattachvolume [options]

Options:
    -h, --help                       Show command line help
    -r, --region REGION
    -v, --volume_id VOLUME_ID        Required
    -i, --instance_id INSTANCE_ID    Required
    -d, --device DEVICE
    -m, --move                       Snapshot, restore, and delete old volume + snapshot if volume is in different AZ. Copies over tags as well
                                     (default: true)
        --log-level LEVEL            Set the logging level
                                     (debug|info|warn|error|fatal)
                                     (Default: info)
```
#### Example IAM Policy
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVolumes",
        "ec2:DescribeSnapshots",
        "ec2:CreateSnapshot",
        "ec2:CreateVolume",
        "ec2:CreateTags",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:DetachVolume"
      ],
      "Resource": "arn:aws:ec2:REGION:ACCOUNT:instance/*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/KEY": "VALUE"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:DeleteVolume"
      ],
      "Resource": "arn:aws:ec2:REGION:ACCOUNT:volume/*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/KEY": "VALUE"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*"
    }
  ]
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake false` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/AWSAttachVolume. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

