Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id

      String :uid
      String :name
      String :image

      Integer :last_login
      String :token
    end
  end

  down do
    drop_table(:users)
  end

end