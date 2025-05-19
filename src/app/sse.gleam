import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/http/response
import gleam/list
import gleam/otp/actor
import gleam/string_tree
import mist

pub type PubSubMessage {
  /// A new client has connected and wants to receive messages.
  Subscribe(client: Subject(String))
  /// A client has disconnected and should no longer receive messages.
  Unsubscribe(client: Subject(String))
  /// A message to forward to all connected clients.
  Publish(String)
}

pub fn pubsub_loop(message: PubSubMessage, clients: List(Subject(String))) {
  case message {
    Subscribe(client) -> {
      echo "➕ Client connected"
      [client, ..clients] |> actor.continue
    }

    Unsubscribe(client) -> {
      echo "➖ Client disconnected"
      clients
      |> list.filter(fn(c) { c != client })
      |> actor.continue
    }

    Publish(message) -> {
      echo "💬 " <> message
      clients |> list.each(process.send(_, message))
      clients |> actor.continue
    }
  }
}

pub fn sse_handler(req, pubsub) {
  mist.server_sent_events(
    req,
    response.new(200),
    init: fn() {
      let client = process.new_subject()
      process.send(pubsub, Subscribe(client))
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
          process.send(pubsub, Unsubscribe(client))
          actor.Stop(process.Normal)
        }
      }
    },
  )
}
