# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::CreditNotes::GeneratedService do
  subject(:webhook_service) { described_class.new(object: credit_note) }

  let(:organization) { create(:organization, webhook_url:) }
  let(:customer) { create(:customer, organization:) }
  let(:invoice) { create(:invoice, organization:, customer:) }
  let(:credit_note) { create(:credit_note, customer:, invoice:) }
  let(:webhook_url) { 'http://foo.bar' }

  describe '.call' do
    let(:lago_client) { instance_double(LagoHttpClient::Client) }

    before do
      allow(LagoHttpClient::Client).to receive(:new)
        .with(organization.webhook_url)
        .and_return(lago_client)
      allow(lago_client).to receive(:post)
    end

    it 'builds payload with credit_note.generated webhook type' do
      webhook_service.call

      expect(LagoHttpClient::Client).to have_received(:new)
        .with(organization.webhook_url)
      expect(lago_client).to have_received(:post) do |payload|
        expect(payload[:webhook_type]).to eq('credit_note.generated')
        expect(payload[:object_type]).to eq('credit_note')
        expect(payload['credit_note'][:customer]).to be_present
      end
    end
  end
end
