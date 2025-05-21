import app/auth
import app/datastar_utils
import context/base.{type Context}
import domain/pubsub.{Subscribe, Unsubscribe}
import given
import gleam/bytes_tree
import gleam/erlang/process
import gleam/function
import gleam/http/response
import gleam/otp/actor
import mist

pub fn sse_handler(req, ctx: Context) {
  let is_authorized = auth.check_cookies(req, ctx)

  use _ <- given.ok(is_authorized, fn(_) {
    response.new(400)
    |> response.set_body(mist.Bytes(bytes_tree.new()))
  })

  mist.server_sent_events(
    req,
    response.new(200),
    init: fn() {
      let client = process.new_subject()
      process.send(ctx.pubsub, Subscribe(client))
      let selector =
        process.new_selector()
        |> process.selecting(client, function.identity)
      actor.Ready(client, selector)
    },
    loop: fn(message, conn, client) {
      let data = message |> datastar_utils.from_datastar_events_to_mist_event
      case mist.send_event(conn, data) {
        Ok(_) -> actor.continue(client)
        Error(_) -> {
          process.send(ctx.pubsub, Unsubscribe(client))
          actor.Stop(process.Normal)
        }
      }
    },
  )
}
