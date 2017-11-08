#!/usr/bin/env ruby
# Ruby script to encrypt the contents of an S3 bucket with your specified credentials 
# KMS key must live in region you specify

begin
  require 'aws-sdk'
  require 'optparse'
  require 'pp'
rescue LoadError => e
   raise "Could not load required library - #{e.message.split.last}"
end

def usage()
  puts <<-EOF
Usage: #{$0} [Options]
  This script will encrypt the contents of a S3 bucket to your specified KMS key
    Options
      -a, --access_key_id AWS_ACCESS_KEY_ID
      -s, --secret_access_key AWS_SECRET_ACCESS_KEY
      -r, --region AWS_DEFAULT_REGION
      -b, --bucket S3_BUCKET
      -k, --key KMS_KEY
      -p, --profile AWS_PROFILE_NAME
      -d, --dryrun DRY_RUN
      -h, --help: show usage
  EOF
  exit 1
end

access_key_id = ENV['AWS_ACCESS_KEY_ID'] || nil
secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] || nil
region = ENV['AWS_DEFAULT_REGION'] || nil
bucket = nil
profile_name = nil
client = nil
key = nil

# Get opts
OptionParser.new { |opts|
  opts.on('-a', '--access_key_id AWS_ACCESS_KEY_ID') { |arg| access_key_id = arg }
  opts.on('-s', '--secret_access_key AWS_SECRET_ACCESS_KEY') { |arg| secret_access_key = arg }
  opts.on('-r', '--region AWS_DEFAULT_REGION') { |arg| region = arg }
  opts.on('-b', '--bucket S3_BUCKET') { |arg| bucket = arg }
  opts.on('-k', '--key KMS_KEY') { |arg| key = arg }
  opts.on('-p', '--profile AWS_PROFILE') { |arg| profile_name = arg }
  opts.on('-d', '--dryrun DRY_RUN') { |arg| dry_run = arg }
  opts.on('-h', '--help') { usage }
}.parse!

# Setup AWS Config
Aws.use_bundled_cert! # To make this work on Windows
puts "AWS Region: [#{region}]"
puts "S3 Bucket: [#{bucket}]"
if profile_name != nil then
  puts "Using AWS Profile: [#{profile_name}]"
  credentials = Aws::SharedCredentials.new(profile_name: profile_name)
  client = Aws::S3::Client.new(
    credentials: credentials,
    region: region
  )
else
  puts "AWS Access Key ID: [#{access_key_id}]"
  puts "AWS Secret Access Key: [#{secret_access_key}]"
  client = Aws::S3::Client.new(
    access_key_id: access_key_id,
    secret_access_key: secret_access_key,
    region: region,
    signature_version: 'v4'
  )
end

# Establish our S3 connection
s3 = Aws::S3::Resource.new(client: client)
s3 = s3.bucket(bucket)

# Get S3 Object encrytion status
s3.objects.each do |obj|
 encryption = s3.object(obj.key).server_side_encryption
 # Now we encrypt any file that isn't already encrypted and let the user know
 if encryption != "aws:kms"
   then puts "S3 file [#{obj.key}] is NOT encrypted! Encrypting now."
   s3.object(obj.key).copy_to(s3.object(obj.key), server_side_encryption:'aws:kms', ssekms_key_id:key)
 else puts "[#{obj.key}] already encrypted"
 end
end
