import app/context
import app/router
import app/sse
import dotenv_conf as env
import gleam/erlang/process
import gleam/http/request
import gleam/otp/actor
import infra/credentials
import infra/session
import infra/user
import mist
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  use file <- env.read_file(".env")
  wisp.configure_logger()

  let ip = env.read_string_or("IP", file, "0.0.0.0")
  let port = env.read_int_or("PORT", file, 8080)

  let secret_key_base = wisp.random_string(64)

  let assert Ok(pubsub) = actor.start([], sse.pubsub_loop)

  let ctx =
    context.Context(
      static_directory: static_directory(),
      user_repository: user.get_file_repository(),
      session_repository: session.get_file_repository(),
      credentials_repository: credentials.get_file_repository(),
      pubsub: pubsub,
    )

  let handler = router.handle_request(_, ctx)

  let assert Ok(_) =
    mist.new(fn(req) {
      case request.path_segments(req) {
        ["api", "events"] -> sse.sse_handler(req, pubsub)
        _ -> wisp_mist.handler(handler, secret_key_base)(req)
      }
    })
    |> mist.bind(ip)
    |> mist.port(port)
    |> mist.start_http

  process.sleep_forever()
}

pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("stars")
  priv_directory <> "/static"
}
