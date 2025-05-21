import datastar
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor

pub type DSEventType {
  EventExecuteScript
  EventMergeFragment
  EventMergeSignals
  EventRemoveFragments
  EventRemoveSignals
}

pub type DatastarEvents =
  List(datastar.Event)

pub type DSEvent {
  DSEvent(event: DSEventType, data: DatastarEvents)
}

pub type PubSubMessage {
  Subscribe(client: Subject(DSEvent))
  Unsubscribe(client: Subject(DSEvent))
  Publish(message: DSEvent)
}

pub fn pubsub_loop(
  message: PubSubMessage,
  clients: List(Subject(DSEvent)),
) {
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
