class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.float :price
      t.string :product_name
      t.integer :status

      t.timestamps
    end
  end
end
