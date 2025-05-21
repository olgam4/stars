import app/auth
import context/base.{type Context}
import domain/pubsub.{type PubSubMessage, Publish, Subscribe, Unsubscribe}
import given
import gleam/bytes_tree
import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/http/response
import gleam/list
import gleam/otp/actor
import gleam/string_tree
import mist

pub fn pubsub_loop(message: PubSubMessage, clients: List(Subject(String))) {
  case message {
    Subscribe(client) -> {
      [client, ..clients] |> actor.continue
    }

    Unsubscribe(client) -> {
      clients
      |> list.filter(fn(c) { c != client })
      |> actor.continue
    }

    Publish(message) -> {
      clients |> list.each(process.send(_, message))
      clients |> actor.continue
    }
  }
}

pub fn sse_handler(req, ctx: Context) {
  let is_authorized = auth.check_cookies(req, ctx)

  use _ <- given.ok(is_authorized, fn(_) {
    response.new(403)
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
      case
        mist.send_event(
          conn,
          message
            |> string_tree.from_string
            |> mist.event
            |> mist.event_name("datastar-merge-fragments"),
        )
      {
        Ok(_) -> actor.continue(client)
        Error(_) -> {
          process.send(ctx.pubsub, Unsubscribe(client))
          actor.Stop(process.Normal)
        }
      }
    },
  )
}
