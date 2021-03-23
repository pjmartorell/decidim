# frozen_string_literal: true

module Decidim
  module Votings
    module Census
      module Admin
        class CreateDatumJob < ApplicationJob
          queue_as :default

          def perform(user, dataset, csv_row)
            Decidim::Votings::Census::Admin::IncrementDatasetProcessedRows.call(dataset)

            return if user.blank? || dataset.blank? || csv_row.blank?

            params = {
              document_number: csv_row[0],
              document_type: csv_row[1],
              birthdate: csv_row[2],
              full_name: csv_row[3],
              full_address: csv_row[4],
              postal_code: csv_row[5],
              mobile_phone_number: csv_row[6],
              email: csv_row[7]
            }

            datum_form = DatumForm.from_params(params)
                                  .with_context(
                                    current_user: user,
                                    dataset: dataset,
                                    voting: dataset.voting
                                  )

            CreateDatum.call(datum_form, dataset, user)
          end
        end
      end
    end
  end
end
