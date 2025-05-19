import domain/user
import gleam/list
import gleam/result
import gsv
import simplifile

pub fn get_nil_repository() -> user.Repository {
  let create = fn(_) { Error(user.Unexpected) }
  let get = fn(_) { Error(user.Unexpected) }
  let get_by_name = fn(_) { Error(user.Unexpected) }

  user.Repository(get, create, get_by_name)
}

pub fn get_file_repository() -> user.Repository {
  let filepath = "./user-db.csv"
  let exists = result.unwrap(simplifile.is_file(filepath), False)

  let _ = case exists {
    True -> Ok(Nil)
    False -> simplifile.create_file(at: filepath)
  }
  |> result.replace_error(user.Unexpected)

  let create = fn(user: user.User) {
    let row = user.id <> "," <> user.name <> "\n"
    filepath
    |> simplifile.append(row)
    |> result.replace_error(user.Unexpected)
  }

  let get = fn(required_id) {
    use file <- result.try(
      simplifile.read(from: filepath)
      |> result.replace_error(user.Unexpected),
    )
    use lists <- result.try(
      gsv.to_lists(file) |> result.replace_error(user.Unexpected),
    )
    let users =
      list.map(lists, fn(row) {
        case row {
          [id, name] -> #(id, user.User(id, name))
          _ -> #("", user.User("", ""))
        }
      })
    case list.key_find(users, required_id) {
      Error(_) -> Error(user.NotFound)
      Ok(found) -> Ok(found)
    }
  }

  let get_by_name = fn(required_name) {
    use file <- result.try(
      simplifile.read(from: filepath)
      |> result.replace_error(user.Unexpected),
    )
    use lists <- result.try(
      gsv.to_lists(file) |> result.replace_error(user.Unexpected),
    )
    let users =
      list.map(lists, fn(row) {
        case row {
          [id, name] -> #(name, user.User(id, name))
          _ -> #("", user.User("", ""))
        }
      })
    case list.key_find(users, required_name) {
      Error(_) -> Error(user.NotFound)
      Ok(found) -> Ok(found)
    }
  }

  user.Repository(get, get_by_name, create)
}
