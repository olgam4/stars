import datastar
import domain/pubsub
import gleam/list
import gleam/string
import gleam/string_tree
import mist

fn sanitize(s: String) -> String {
  s
  |> strip_first_word_from_every_line
  |> remove_first_line
  |> remove_last_line
  |> remove_last_line
}

fn remove_last_line(s: String) -> String {
  let lines = string.split(s, "\n")
  let lines = list.reverse(lines)
  let stripped_lines = case lines {
    [_, ..rest] -> list.reverse(rest)
    _ -> lines
  }
  string.join(stripped_lines, "\n")
}

fn remove_first_line(s: String) -> String {
  let lines = string.split(s, "\n")
  let stripped_lines = case lines {
    [_, ..rest] -> rest
    _ -> lines
  }
  string.join(stripped_lines, "\n")
}

fn strip_first_word_from_every_line(s: String) -> String {
  let lines = string.split(s, "\n")
  let stripped_lines =
    list.map(lines, fn(line) {
      case string.split(line, ": ") {
        [_, stripped] -> stripped
        _ -> line
      }
    })
  string.join(stripped_lines, "\n")
}

fn events_to_string(events: List(datastar.Event)) -> String {
  events
  |> datastar.events_to_string
  |> sanitize
}

pub fn from_datastar_events_to_mist_event(
  ds_event: pubsub.DSEvent,
) -> mist.SSEEvent {
  let data =
    ds_event.data
    |> events_to_string
    |> string_tree.from_string
    |> mist.event
  case ds_event.event {
    pubsub.EventExecuteScript -> mist.event_name(data, "datastar-execute-script")
    pubsub.EventMergeFragment -> mist.event_name(data, "datastar-merge-fragments")
    pubsub.EventMergeSignals -> mist.event_name(data, "datastar-merge-signals")
    pubsub.EventRemoveFragments -> mist.event_name(data, "datastar-remove-fragments")
    pubsub.EventRemoveSignals -> mist.event_name(data, "datastar-remove-signals")
  }
}
