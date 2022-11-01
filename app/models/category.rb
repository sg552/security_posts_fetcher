class Category < ActiveRecord::Base
  has_many :blogs
  belongs_to :special_column, optional: true
end
