# typed: false

require "rails_helper"
require Rails.root.join(
  "db/migrate/20261030090200_convert_assessment_outcomes_to_enums"
)

RSpec.describe ConvertAssessmentOutcomesToEnums do
  let(:connection) { ActiveRecord::Base.connection }
  let(:table) { :assessment_outcome_migration_examples }

  before do
    connection.create_table(table) do |t|
      t.boolean :result_pass
      t.integer :original_enum_pass
      t.boolean :permanent_roof
      t.boolean :passed
    end
    stub_const(
      "ConvertAssessmentOutcomesToEnums::BOOLEAN_OUTCOMES",
      {assessment_outcome_migration_examples: %i[result_pass]}
    )
  end

  after { connection.drop_table(table) }

  it "preserves historical true, false and unanswered outcomes exactly" do
    connection.execute <<~SQL
      INSERT INTO assessment_outcome_migration_examples
        (result_pass, original_enum_pass, permanent_roof, passed)
      VALUES (TRUE, 2, FALSE, TRUE), (FALSE, 1, TRUE, FALSE),
        (NULL, NULL, NULL, NULL)
    SQL

    migration = described_class.new
    migration.suppress_messages { migration.up }

    rows = connection.select_rows(<<~SQL)
      SELECT result_pass, original_enum_pass, permanent_roof, passed
      FROM assessment_outcome_migration_examples ORDER BY id
    SQL
    expect(rows).to eq([
      [1, 2, 0, 1],
      [0, 1, 1, 0],
      [nil, nil, nil, nil]
    ])
    columns = connection.columns(table).index_by(&:name)
    expect(columns.fetch("result_pass").type).to eq(:integer)
    expect(columns.fetch("permanent_roof").type).to eq(:boolean)
    expect(columns.fetch("passed").type).to eq(:boolean)
  end
end
