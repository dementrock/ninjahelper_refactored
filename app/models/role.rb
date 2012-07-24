class Role
  include Mongoid::Document
  
  has_and_belongs_to_many :users
  belongs_to :resource, :polymorphic => true
  
  field :name, :type => String
  index :name, unique: true
  index(
    [
      [:name, Mongo::ASCENDING],
      [:resource_type, Mongo::ASCENDING],
      [:resource_id, Mongo::ASCENDING]
    ],
    unique: true
  )
end
