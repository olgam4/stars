import domain/session
import gleam/list
import gleam/result
import gsv
import simplifile

pub fn get_file_repository() -> session.Repository {
  let filepath = "./session-db.csv"
  let exists = result.unwrap(simplifile.is_file(filepath), False)

  let _ = case exists {
    True -> Ok(Nil)
    False -> simplifile.create_file(at: filepath)
  }
  |> result.replace_error(session.Unexpected)

  let create = fn(session: session.Session) {
    let row =
      session.id
      <> ","
      <> session.user_id
      <> ","
      <> session.expires_at
      <> ","
      <> session.revoked_at
      <> "\n"
    filepath
    |> simplifile.append(row)
    |> result.replace_error(session.Unexpected)
  }

  let get = fn(required_id) {
    use file <- result.try(
      simplifile.read(from: filepath)
      |> result.replace_error(session.Unexpected),
    )
    use lists <- result.try(
      gsv.to_lists(file) |> result.replace_error(session.Unexpected),
    )
    let sessions =
      list.map(lists, fn(row) {
        case row {
          [id, user_id, expires_at, revoked_at] -> #(
            id,
            session.Session(id, user_id, expires_at, revoked_at),
          )
          _ -> #("", session.Session("", "", "", ""))
        }
      })
    case list.key_find(sessions, required_id) {
      Error(_) -> Error(session.NotFound)
      Ok(found) -> Ok(found)
    }
  }

  session.Repository(get, create)
}
