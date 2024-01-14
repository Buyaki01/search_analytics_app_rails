class CreateSearches < ActiveRecord::Migration[6.0]
  def change
    create_table :searches do |t|
      t.string :query
      t.string :user_ip
      t.datetime :timestamp

      t.timestamps
    end
  end
end
