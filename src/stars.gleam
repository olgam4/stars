import app/router
import app/sse
import context/dev
import gleam/erlang/process
import gleam/http/request
import mist
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  wisp.configure_logger()
  let ctx = dev.get_dev_context()
  let secret_key_base = wisp.random_string(64)
  let handler = router.handle_request(_, ctx)

  let assert Ok(_) =
    mist.new(fn(req) {
      case request.path_segments(req) {
        ["api", "events"] -> sse.sse_handler(req, ctx.pubsub)
        _ -> wisp_mist.handler(handler, secret_key_base)(req)
      }
    })
    |> mist.bind(ctx.ip)
    |> mist.port(ctx.port)
    |> mist.start_http

  process.sleep_forever()
}

pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("stars")
  priv_directory <> "/static"
}
