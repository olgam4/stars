import argus
import context/base.{type Context}
import datastar
import datastar_wisp
import domain/session
import given
import gleam/bool
import gleam/http.{Post}
import gleam/json
import gleam/list
import gleam/time/duration
import gleam/time/timestamp
import gwt
import wisp

pub fn login(req, ctx: Context) {
  use <- wisp.require_method(req, Post)
  use formdata <- wisp.require_form(req)
  let assert Ok(username) = list.key_find(formdata.values, "username")
  let assert Ok(password) = list.key_find(formdata.values, "password")

  use user <- given.ok(
    ctx.user_repository.get_by_name(username),
    fn(_) { wisp.not_found() },
  )

  use credentials <- given.ok(
    ctx.credentials_repository.get(user.id),
    fn(_) { wisp.not_found() },
  )

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
