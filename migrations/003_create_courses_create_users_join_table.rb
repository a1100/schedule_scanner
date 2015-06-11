Sequel.migration do
  up do
    create_table(:courses_users) do
      primary_key :id
      foreign_key :user_id
      foreign_key :course_id
    end
  end

  down do
    drop_table(:courses_users)
  end
end