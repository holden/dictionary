class RenameConceptnetToConceptNet < ActiveRecord::Migration[7.0]
  def change
    rename_column :topics, :conceptnet_id, :concept_net_id
  end
end 