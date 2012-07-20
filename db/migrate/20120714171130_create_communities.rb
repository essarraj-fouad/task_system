class CreateCommunities < ActiveRecord::Migration
  def change
    create_table :communities do |t|
      t.string :name
      t.string :subdomain
      t.string :max_users, default: 20
      t.timestamps
    end
  end
end
