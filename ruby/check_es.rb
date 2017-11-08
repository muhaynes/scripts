#!/usr/bin/ruby
# Nagios check to build Elasticsearch queries to alert upon
# ./check_es.rb -c elastic1.domain.com -i "hostname:server1.domain.local|severity:ERROR|message:*nginx*" -t now-15m -w 2 -C 4 -o ">"

require 'net/http'
require 'json'
require 'uri'
require 'optparse'

def usage()
  puts <<-EOF
Usage: #{$0} [Options]
  Checks ElasticSearch with specified Source/String and alerts based on the number of returned results
    Options
      -c, --cluster CLUSTER
      -i, --input INPUT: key/values for search parameters, seperated by | 
      -t, --timeframe TIMEFRAME: relative, now-1h etc
      -o, --operator OPERATOR: ruby operator symbols < > = etc
      -w, --warn WARN
      -C, --crit CRIT
      -H, --help: show usage
    Example: ./check_es.rb -c elastic1.domain.com -i "hostname:server1.domain.local|severity:ERROR|message:*nginx*" -t now-15m -w 2 -C 4 -o ">"
  EOF
  exit 1
end

cluster = nil
input = nil
timeframe = nil
operator = nil
warn = nil
crit = nil

# Get opts
OptionParser.new { |opts|
  opts.on('-c', '--cluster CLUSTER') { |arg| cluster = arg }
  opts.on('-h', '--input INPUT') { |arg| input = arg }
  opts.on('-t', '--timeframe TIMEFRAME') { |arg| timeframe = arg }
  opts.on('-o', '--operator OPERATOR') { |arg| operator = arg }
  opts.on('-w', '--warn WARN') { |arg| warn = arg }
  opts.on('-C', '--crit CRIT') { |arg| crit = arg }
  opts.on('-H', '--help') { usage }
}.parse!

def fquery(values)
  { fquery: { query: { query_string: query_string(values) } } }
end

def query_string(values)
  { query: %{#{values.first}:("#{values.last}")} }
end

def must(params)
  params.map { |param| fquery param.split(':') }
end

def range(timeframe)
  { range: { '@timestamp' => { gt: timeframe } } }
end

def filter(timeframe, params)
  { filter: { bool: { must: [ range(timeframe), must(params) ].flatten } } }
end

def pretty_json(data)
  JSON.pretty_generate data
end

params    = input.split("|")
result    = filter timeframe, params


date=Time.now.strftime("%Y.%m.%d")
url="http://#{cluster}:9200/*-logstash-#{date}/_search?pretty=1"
uri = URI.parse(url)
data = JSON.pretty_generate result

headers = {"Content-Type" => "application/json"}

http = Net::HTTP.new(uri.host,uri.port)

http.open_timeout = 10
http.read_timeout = 10

response = http.post(uri.path,data,headers)

obj = JSON.parse(response.body)

result = obj['hits']['total']

if result.public_send(operator, crit.to_i)
  puts "Critical: #{result} hits is #{operator} than #{crit} critical threshold"
  exit 2
elsif result.public_send(operator, warn.to_i)
  puts "Warning: #{result} hits is #{operator} than #{warn} warning threshold"
  exit 1
else
  puts "OK #{result} results within threshold"
  exit 0
end
