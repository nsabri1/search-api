require "spec_helper"
require "spec/support/ranker_test_helpers"

RSpec.describe "HealthcheckTest" do
  include RankerTestHelpers

  let(:queues) {
    { "bulk" => 2, "default" => 1 }
  }
  let(:queue_latency) { 1.seconds }

  before do
    allow_any_instance_of(Sidekiq::Stats).to receive(:queues).and_return(queues)
    allow_any_instance_of(Sidekiq::Queue).to receive(:latency).and_return(queue_latency)
    allow_any_instance_of(Elasticsearch::API::Cluster::ClusterClient).to receive(:health).and_return("status" => "green")
    stub_ranker_status_to_be_ok
  end

  describe "#redis_connectivity check" do
    # We only check for cannot connect because govuk_app_config has tests for this
    context "when Sidekiq CANNOT connect to Redis" do
      before do
        allow(Sidekiq).to receive(:redis_info).and_raise(Errno::ECONNREFUSED)
      end

      it "returns a critical status" do
        get "/healthcheck"

        expect(parsed_response["status"]).to eq "critical"
      end
    end
  end

  describe "#reranker_healthcheck check" do
    # We only check for cannot connect because govuk_app_config has tests for this
    context "when reranker healthcheck fails" do
      before do
        stub_ranker_container_doesnt_exist
      end

      it "returns a warning status" do
        get "/healthcheck"
        expect(parsed_response.dig("checks", "reranker_healthcheck", "status")).to eq "warning"
      end
    end

    context "when reranker healthcheck passes" do
      it "returns an OK status" do
        get "/healthcheck"
        expect(parsed_response["status"]).to eq "ok"
        expect(parsed_response.dig("checks", "reranker_healthcheck", "status")).to eq "ok"
      end
    end
  end

  describe "#elasticsearch_connectivity check" do
    context "when elasticsearch CANNOT be connected to" do
      before do
        allow_any_instance_of(Elasticsearch::API::Cluster::ClusterClient).to receive(:health).and_raise(Faraday::Error)
      end

      it "returns a critical status" do
        get "/healthcheck"

        expect(parsed_response["status"]).to eq "critical"
        expect(parsed_response.dig("checks", "elasticsearch_connectivity", "status")).to eq "critical"
      end
    end

    context "when elasticsearch CAN be connected to" do
      it "returns an OK status" do
        get "/healthcheck"

        expect(parsed_response["status"]).to eq "ok"
        expect(parsed_response.dig("checks", "elasticsearch_connectivity", "status")).to eq "ok"
      end
    end
  end

  describe "#sidekiq_queue_latency check" do
    before do
      allow(Sidekiq).to receive(:redis_info).and_return({})
    end

    context "when queue latency is 2 (seconds)" do
      let(:queue_latency) { 2.seconds }

      it "retuns an OK status" do
        get "/healthcheck"

        expect(last_response).to be_ok

        expect(parsed_response.dig("checks", "sidekiq_queue_latency", "status")).to eq "ok"
      end
    end

    context "when queue latency is high" do
      let(:queue_latency) { 32.seconds }

      it "retuns a warning status" do
        get "/healthcheck"

        expect(parsed_response["status"]).to eq "warning"
        expect(parsed_response.dig("checks", "sidekiq_queue_latency", "status")).to eq "warning"
      end
    end


    context "when queue latency is very high" do
      let(:queue_latency) { 2.minutes }

      it "retuns a critical status" do
        get "/healthcheck"

        expect(parsed_response["status"]).to eq("critical")
        expect(parsed_response.dig("checks", "sidekiq_queue_latency", "status")).to eq "critical"
      end
    end
  end
end
