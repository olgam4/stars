import gleam/list
import gleam/string

pub fn sanitize(s: String) -> String {
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
