# frozen_string_literal: true

require "spec_helper"

describe Decidim::Votings::Census::Admin::GenerateAccessCodesJob do
  let(:organization) { create(:organization) }
  let(:dataset) { create(:dataset, organization: organization, status: :review_data) }
  let(:user) { create(:user, :admin, organization: organization) }

  describe "queue" do
    it "is queued to events" do
      expect(described_class.queue_name).to eq "default"
    end
  end

  describe "perform" do
    context "when the input is NOT valid" do
      context "when the dataset is missing" do
        let(:dataset) { nil }

        it "does not update the dataset nor the data" do
          expect(Decidim::Votings::Census::Admin::UpdateDataset).not_to receive(:call)
          expect(Decidim::Votings::Census::Admin::GenerateAccessCodes).not_to receive(:call)

          described_class.perform_now(dataset, user)
        end
      end

      context "when the dataset is not in the correct status" do
        let(:dataset) { create(:dataset, organization: organization, status: :export_codes) }

        it "does not update the dataset nor the data" do
          expect(Decidim::Votings::Census::Admin::UpdateDataset).not_to receive(:call)
          expect(Decidim::Votings::Census::Admin::GenerateAccessCodes).not_to receive(:call)

          described_class.perform_now(dataset, user)
        end
      end

      context "when the user is missing" do
        let(:user) { nil }

        it "does not update the dataset nor the data" do
          expect(Decidim::Votings::Census::Admin::UpdateDataset).not_to receive(:call)
          expect(Decidim::Votings::Census::Admin::GenerateAccessCodes).not_to receive(:call)

          described_class.perform_now(dataset, user)
        end
      end
    end

    context "when this input is valid" do
      it "delegates the work to the commands" do
        expect(Decidim::Votings::Census::Admin::UpdateDataset)
          .to receive(:call)
          .with(dataset, { status: :generate_codes }, user)

        expect(Decidim::Votings::Census::Admin::UpdateDataset)
          .to receive(:call)
          .with(dataset, { status: :export_codes }, user)

        expect(Decidim::Votings::Census::Admin::GenerateAccessCodes)
          .to receive(:call)
          .with(dataset, user)

        described_class.perform_now(dataset, user)
      end

      it "updates the dataset status" do
        described_class.perform_now(dataset, user)

        expect(dataset.reload.status).to match("export_codes")
      end
    end
  end
end
