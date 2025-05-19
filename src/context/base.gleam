import gleam/erlang/process
import app/sse
import domain/credentials
import domain/session
import domain/user

pub type Context {
  Context(
    ip: String,
    port: Int,

    static_directory: String,
    user_repository: user.Repository,
    session_repository: session.Repository,
    credentials_repository: credentials.Repository,

    pubsub: process.Subject(sse.PubSubMessage),
    nanoid: fn(Int) -> String,

    secret_key: String,
    csrf_token: String,
    cookie_name: String,
  )
}
