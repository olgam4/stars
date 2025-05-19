pub type User {
  User(id: Id, name: String)
}

pub type Id =
  String

pub type RepositoryError {
  NotFound
  Unexpected
}

pub type Repository {
  Repository(
    get: fn(Id) -> Result(User, RepositoryError),
    get_by_name: fn(String) -> Result(User, RepositoryError),
    create: fn(User) -> Result(Nil, RepositoryError),
  )
}
