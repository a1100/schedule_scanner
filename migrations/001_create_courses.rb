Sequel.migration do
  up do
    create_table(:courses) do
      primary_key :id

      String :course_id
      String :title
      String :teacher
      String :period
      String :room
      String :days
      String :quarters

    end
  end

  down do
    drop_table(:courses)
  end

end