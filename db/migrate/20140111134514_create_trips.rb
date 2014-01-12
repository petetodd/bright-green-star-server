class CreateTrips < ActiveRecord::Migration
  def change
    create_table :trips do |t|
      t.string :name
      t.string :typetrip
      t.text :content

      t.timestamps
    end
  end
end
