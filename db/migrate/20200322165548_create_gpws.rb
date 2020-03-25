class CreateGpws < ActiveRecord::Migration
  def change
    create_table :gpws do |t|
      t.string :index
      t.date :date
      t.float :open
      t.float :close
      t.float :high
      t.float :low
      t.float :change
      t.float :trades
      t.float :tornover
      t.integer :volume

      t.timestamps null: false
    end
  end
end
