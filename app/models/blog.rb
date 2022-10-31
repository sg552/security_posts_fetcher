class Blog < ActiveRecord::Base
  belongs_to :categories, optional: true
end
