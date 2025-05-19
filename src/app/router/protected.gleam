import gleam/dynamic/decode
import gleam/string_tree
import views/components/home
import views/index
import gleam/time/timestamp
import context/base.{type Context}
import gleam/result
import gleam/order
import gwt
import wisp.{type Response}

pub fn protected_route(
  req,
  ctx: Context,
  next: fn() -> Response,
) -> Response {
  let is_authorized = {
    use cookie <- result.try(wisp.get_cookie(req, ctx.cookie_name, wisp.Signed))
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

    case
      timestamp.compare(now, expires_at),
      timestamp.compare(now, revoked_at)
    {
      order.Lt, order.Lt -> Ok(Nil)
      _, _ -> Error(Nil)
    }
  }

  let index = index.index(home.redirect_to_login, ctx)
  case is_authorized {
    Ok(Nil) -> next()
    _ -> wisp.html_response(string_tree.from_string(index), 401)
  }
}
