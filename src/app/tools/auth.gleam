import context/base.{type Context}
import gleam/bit_array
import gleam/crypto
import gleam/dynamic/decode
import gleam/http/request
import gleam/list
import gleam/order
import gleam/result
import gleam/time/timestamp
import gwt

fn verify_signed_message(
  secret_key_base: String,
  message: String,
) -> Result(BitArray, Nil) {
  crypto.verify_signed_message(message, <<secret_key_base:utf8>>)
}

pub fn check_cookies(req, ctx: Context) {
  let cookies = request.get_cookies(req)
  use token <- result.try(
    list.key_find(cookies, ctx.cookie_name) |> result.replace_error(Nil),
  )
  use value <- result.try(verify_signed_message(ctx.secret_key_base, token))
  use cookie <- result.try(bit_array.to_string(value))

  use jwt <- result.try(
    gwt.from_signed_string(cookie, ctx.secret_key) |> result.replace_error(Nil),
  )
  use session_id <- result.try(
    gwt.get_payload_claim(jwt, "session_id", decode.string)
    |> result.replace_error(Nil),
  )
  use session <- result.try(
    ctx.session_repository.get(session_id) |> result.replace_error(Nil),
  )
  let now = timestamp.system_time()
  use expires_at <- result.try(
    timestamp.parse_rfc3339(session.expires_at) |> result.replace_error(Nil),
  )
  let revoked_at = case session.revoked_at {
    "" -> session.expires_at
    _ -> session.revoked_at
  }
  use revoked_at <- result.try(
    timestamp.parse_rfc3339(revoked_at) |> result.replace_error(Nil),
  )

  case timestamp.compare(now, expires_at), timestamp.compare(now, revoked_at) {
    order.Lt, order.Lt -> Ok(Nil)
    _, _ -> Error(Nil)
  }
}
