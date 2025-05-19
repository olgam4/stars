import gleam/string
import domain/credentials
import gsv
import gleam/list
import gleam/result
import simplifile

pub fn get_file_repository() -> credentials.Repository {
  let filepath = "./creds-db.csv"
  let exists = result.unwrap(simplifile.is_file(filepath), False)

  let _ = case exists {
    True -> Ok(Nil)
    False -> simplifile.create_file(at: filepath)
  }
  |> result.replace_error(credentials.Unexpected)

  let create = fn(credentials: credentials.Credentials) {
    let row = credentials.user_id <> "," <> credentials.hash <> "\n"
    filepath
    |> simplifile.append(row)
    |> result.replace_error(credentials.Unexpected)
  }

  let get = fn(required_id) {
    use file <- result.try(
      simplifile.read(from: filepath)
      |> result.replace_error(credentials.Unexpected),
    )
    use lists <- result.try(
      gsv.to_lists(file) |> result.replace_error(credentials.Unexpected),
    )
    let credentials_collection =
      list.map(lists, fn(row) {
        case row {
          [id, ..hash] -> #(id, credentials.EmailPassword(id, string.join(hash, ",")))
          _ -> #("", credentials.EmailPassword("", ""))
        }
      })
    case list.key_find(credentials_collection, required_id) {
      Error(_) -> Error(credentials.NotFound)
      Ok(found) -> Ok(found)
    }
  }

  credentials.Repository(get, create)
}
