class AddSpecialColumnIdToCategories < ActiveRecord::Migration[7.0]
  def change
    add_column :categories, :special_column_id, :integer
  end
end
