import dotenv_conf
import datastar_wisp
import datastar
import gleam/json
import gwt
import domain/session
import gleam/time/duration
import gleam/time/timestamp
import glanoid
import argus
import gleam/result
import gleam/bool
import gleam/list
import wisp
import app/context
import gleam/http.{Post}

const cookie_name = "__Stars_id"

pub fn login(req, ctx: context.Context) {
  use <- wisp.require_method(req, Post)
  use formdata <- wisp.require_form(req)
  let assert Ok(username) = list.key_find(formdata.values, "username")
  let assert Ok(password) = list.key_find(formdata.values, "password")

  let maybe_user = ctx.user_repository.get_by_name(username)
  use <- bool.guard(result.is_error(maybe_user), return: wisp.not_found())
  let assert Ok(user) = maybe_user

  let maybe_credentials = ctx.credentials_repository.get(user.id)
  use <- bool.guard(
    result.is_error(maybe_credentials),
    return: wisp.not_found(),
  )
  let assert Ok(credentials) = maybe_credentials

  let assert Ok(result) = argus.verify(credentials.hash, password)
  use <- bool.guard(!result, return: wisp.not_found())

  let assert Ok(nanoid) = glanoid.make_generator(glanoid.default_alphabet)
  let session_id = nanoid(10)

  let expires_at =
    timestamp.system_time()
    |> timestamp.add(duration.hours(72))
    |> timestamp.to_rfc3339(duration.hours(0))

  let _ =
    ctx.session_repository.create(session.Session(
      session_id,
      user.id,
      expires_at,
      "",
    ))

  use env <- dotenv_conf.read_file(".env")
  let secret_key = dotenv_conf.read_string_or("SECRET_KEY", env, "secret")

  let jwt =
    gwt.new()
    |> gwt.set_payload_claim("session_id", json.string(session_id))
    |> gwt.to_signed_string(gwt.HS512, secret_key)

  let events = [
    datastar.execute_script("window.location='/'")
    |> datastar.execute_script_end,
  ]

  wisp.ok()
  |> wisp.set_cookie(req, cookie_name, jwt, wisp.Signed, 60 * 60 * 24)
  |> datastar_wisp.send(events)
}
