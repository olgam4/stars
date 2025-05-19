import domain/user

pub type Session {
  Session(id: Id, user_id: user.Id, expires_at: String, revoked_at: String)
}

pub type Id =
  String

pub type RepositoryError {
  NotFound
  Unexpected
}

pub type Repository {
  Repository(
    get: fn(Id) -> Result(Session, RepositoryError),
    create: fn(Session) -> Result(Nil, RepositoryError),
  )
}
