import gleam/erlang/process
import app/sse
import domain/credentials
import domain/session
import domain/user

pub type Context {
  Context(
    static_directory: String,
    user_repository: user.Repository,
    session_repository: session.Repository,
    credentials_repository: credentials.Repository,
    pubsub: process.Subject(sse.PubSubMessage),
  )
}
