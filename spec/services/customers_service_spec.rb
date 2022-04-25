# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CustomersService, type: :service do
  subject(:customers_service) { described_class.new(user) }

  let(:user) { nil }
  let(:membership) { create(:membership) }
  let(:organization) { membership.organization }

  describe 'create_from_api' do
    let(:create_args) do
      {
        customer_id: SecureRandom.uuid,
        name: 'Foo Bar',
      }
    end

    it 'creates a new customer' do
      result = customers_service.create_from_api(
        organization: organization,
        params: create_args,
      )

      expect(result).to be_success

      customer = result.customer
      expect(customer.id).to be_present
      expect(customer.organization_id).to eq(organization.id)
      expect(customer.customer_id).to eq(create_args[:customer_id])
      expect(customer.name).to eq(create_args[:name])
    end

    context 'when customer already exists' do
      let!(:customer) do
        create(:customer, organization: organization, customer_id: create_args[:customer_id])
      end

      it 'updates the customer' do
        result = customers_service.create_from_api(
          organization: organization,
          params: create_args,
        )

        expect(result).to be_success
        expect(result.customer).to eq(customer)
        expect(result.customer.name).to eq(create_args[:name])
      end
    end

    context 'with validation error' do
      let(:create_args) do
        {
          name: 'Foo Bar',
        }
      end

      it 'return a failed result' do
        result = customers_service.create_from_api(
          organization: organization,
          params: create_args,
        )

        expect(result).not_to be_success
      end
    end
  end

  describe 'create' do
    let(:create_args) do
      {
        customer_id: SecureRandom.uuid,
        name: 'Foo Bar',
        organization_id: organization.id,
      }
    end

    it 'creates a new customer' do
      result = customers_service.create(**create_args)

      aggregate_failures do
        expect(result).to be_success

        customer = result.customer
        expect(customer.id).to be_present
        expect(customer.organization_id).to eq(organization.id)
        expect(customer.customer_id).to eq(create_args[:customer_id])
        expect(customer.name).to eq(create_args[:name])
      end
    end

    context 'when customer already exists' do
      let(:customer) do
        create(:customer, organization: organization, customer_id: create_args[:customer_id])
      end

      before { customer }

      it 'return a failed result' do
        result = customers_service.create(**create_args)

        expect(result).not_to be_success
      end
    end

    context 'with validation error' do
      let(:create_args) do
        {
          name: 'Foo Bar',
        }
      end

      it 'return a failed result' do
        result = customers_service.create(**create_args)

        expect(result).not_to be_success
      end
    end
  end

  describe 'update' do
    let(:user) { membership.user }

    let(:customer) { create(:customer, organization: organization) }
    let(:customer_id) { SecureRandom.uuid }

    let(:update_args) do
      {
        id: customer.id,
        name: 'Updated customer name',
        customer_id: customer_id,
      }
    end

    it 'updates a customer' do
      result = customers_service.update(**update_args)

      updated_customer = result.customer
      aggregate_failures do
        expect(updated_customer.name).to eq('Updated customer name')
      end
    end

    context 'with validation error' do
      let(:customer_id) { nil }

      it 'returns an error' do
        result = customers_service.update(**update_args)

        expect(result).not_to be_success
        expect(result.error_code).to eq('unprocessable_entity')
      end
    end

    context 'when attached to a subscription' do
      before do
        create(:subscription, customer: customer)
      end

      it 'updates only the name' do
        result = customers_service.update(**update_args)

        updated_customer = result.customer
        aggregate_failures do
          expect(updated_customer.name).to eq('Updated customer name')
          expect(updated_customer.customer_id).to eq(customer.customer_id)
        end
      end
    end
  end

  describe 'destroy' do
    subject(:customers_service) { described_class.new(membership.user) }

    let(:membership) { create(:membership) }
    let(:organization) { membership.organization }
    let(:customer) { create(:customer, organization: organization) }

    it 'destroys the customer' do
      id = customer.id

      expect do
        customers_service.destroy(
          id: id,
        )
      end.to change(Customer, :count).by(-1)
    end

    context 'when customer is not found' do
      it 'returns an error' do
        result = customers_service.destroy(
          id: nil,
        )

        expect(result).not_to be_success
        expect(result.error).to eq('not_found')
      end
    end

    context 'when customer is attached to subscription' do
      before do
        create(:subscription, customer: customer)
      end

      it 'returns an error' do
        result = customers_service.destroy(
          id: customer.id,
        )

        expect(result).not_to be_success
        expect(result.error_code).to eq('forbidden')
      end
    end
  end
end
