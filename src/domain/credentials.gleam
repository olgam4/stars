import domain/user

pub type Credentials {
  EmailPassword(user_id: user.Id, hash: Hash)
}

pub type Hash =
  String

pub type CredentialsError {
  NotFound
  Unexpected
}

pub type Repository {
  Repository(
    get: fn(user.Id) -> Result(Credentials, CredentialsError),
    create: fn(Credentials) -> Result(Nil, CredentialsError),
  )
}
