import domain/pubsub
import wisp
import glanoid
import gleam/otp/actor
import infra/credentials
import infra/session
import infra/user
import context/base.{Context}
import dotenv_conf as env

pub fn get_dev_context() {
  use file <- env.read_file(".env")
  let ip = env.read_string_or("IP", file, "0.0.0.0")
  let port = env.read_int_or("PORT", file, 8080)
  let secret_key = env.read_string_or("SECRET_KEY", file, "secret")
  let csrf_token = env.read_string_or("CSRF_TOKEN", file, "secret")
  let assert Ok(pubsub) = actor.start([], pubsub.pubsub_loop)
  let assert Ok(nanoid) = glanoid.make_generator(glanoid.default_alphabet)
  let cookie_name = "__Stars_id"
  let secret_key_base = wisp.random_string(64)

  Context(
    ip: ip,
    port: port,
    static_directory: base.static_directory(),
    user_repository: user.get_file_repository(),
    session_repository: session.get_file_repository(),
    credentials_repository: credentials.get_file_repository(),
    pubsub: pubsub,
    nanoid: nanoid,
    secret_key: secret_key,
    csrf_token: csrf_token,
    cookie_name: cookie_name,
    secret_key_base: secret_key_base,
  )
}
