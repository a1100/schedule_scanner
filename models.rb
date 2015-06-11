class Course < Sequel::Model
  many_to_many :users
end


class User < Sequel:: Model
  many_to_many :courses
end