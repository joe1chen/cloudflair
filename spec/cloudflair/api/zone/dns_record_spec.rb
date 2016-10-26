require 'spec_helper'

describe Cloudflair::DnsRecord do
  let(:faraday_stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday) do
    Faraday.new(url: 'https://api.cloudflare.com/client/v4/', headers: Cloudflair::Connection.headers) do |faraday|
      faraday.adapter :test, faraday_stubs
      faraday.request :json
      faraday.response :json, content_type: /\bjson$/
    end
  end

  let(:zone_identifier) { '023e105f4ecef8ad9ca31a8372d0c353' }
  let(:record_identifier) { '372e67954025e0ba6aaa6d586b9e0b59' }
  let(:response_json) { File.read('spec/cloudflair/fixtures/zone/dns_record.json') }
  let(:url) { "/client/v4/zones/#{zone_identifier}/dns_records/#{record_identifier}" }
  subject { Cloudflair::DnsRecord.new zone_identifier, record_identifier }

  before do
    faraday_stubs.get(url) do |_env|
      [200, { content_type: 'application/json' }, response_json]
    end
    allow(Faraday).to receive(:new).and_return faraday
  end

  it 'loads the data on demand and caches' do
    expect(faraday).to receive(:get).once.and_call_original

    expect(subject.id).to eq record_identifier
    expect(subject.name).to eq 'example.com'
    expect(subject.type).to eq 'A'
    expect(subject.content).to eq '1.2.3.4'
    expect(subject.ttl).to be 120
    expect(subject.locked).to be false
  end

  it 'reloads the AvailablePlan on request' do
    expect(faraday).to receive(:get).twice.and_call_original

    expect(subject.reload).to be subject
    expect(subject.reload).to be subject
  end
end
