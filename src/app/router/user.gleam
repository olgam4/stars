import app/context
import app/router/protected.{protected_route}
import argus
import domain/credentials
import domain/user
import glanoid
import gleam/bool
import gleam/dynamic/decode
import gleam/http.{Get, Post}
import gleam/json
import gleam/list
import gleam/result
import wisp

pub fn user_router(req: wisp.Request, ctx: context.Context) {
  case req.method {
    Get -> get_user(req, ctx)
    Post -> create_user(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

type UserCreation {
  UserCreation(name: String, password: String)
}

fn user_creation_decoder() -> decode.Decoder(UserCreation) {
  use name <- decode.field("name", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(UserCreation(name, password))
}

fn create_user(req, ctx: context.Context) {
  use <- wisp.require_method(req, Post)
  use <- protected_route(req, ctx)
  use json <- wisp.require_json(req)

  let user_creation = decode.run(json, user_creation_decoder())
  use <- bool.guard(result.is_error(user_creation), return: wisp.bad_request())
  let assert Ok(UserCreation(name, password)) = user_creation

  let assert Ok(nanoid) = glanoid.make_generator(glanoid.default_alphabet)
  let id = nanoid(12)
  let user = user.User(id, name)

  let assert Ok(hashes) =
    argus.hasher()
    |> argus.hash(password, argus.gen_salt())

  let credentials = credentials.EmailPassword(id, hashes.encoded_hash)

  let _ = ctx.user_repository.create(user)
  let _ = ctx.credentials_repository.create(credentials)

  wisp.ok()
  |> wisp.string_body(id)
}

fn get_user(req, ctx: context.Context) {
  use <- wisp.require_method(req, Get)
  use <- protected_route(req, ctx)

  let query = wisp.get_query(req)
  let assert Ok(id) = list.key_find(query, "id")
  let assert Ok(found) = ctx.user_repository.get(id)
  let body =
    json.object([
      #("name", json.string(found.name)),
      #("id", json.string(found.id)),
    ])
    |> json.to_string_tree

  wisp.ok()
  |> wisp.json_body(body)
}
