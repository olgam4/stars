import datastar_wisp
import datastar
import gleam/json
import gwt
import domain/session
import gleam/time/duration
import gleam/time/timestamp
import argus
import gleam/result
import gleam/bool
import gleam/list
import wisp
import context/base.{type Context}
import gleam/http.{Post}

pub fn login(req, ctx: Context) {
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

  let session_id = ctx.nanoid(12)

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

  let jwt =
    gwt.new()
    |> gwt.set_payload_claim("session_id", json.string(session_id))
    |> gwt.to_signed_string(gwt.HS512, ctx.secret_key)

  let events = [
    datastar.execute_script("window.location='/'")
    |> datastar.execute_script_end,
  ]

  wisp.ok()
  |> wisp.set_cookie(req, ctx.cookie_name, jwt, wisp.Signed, 60 * 60 * 24)
  |> datastar_wisp.send(events)
}
