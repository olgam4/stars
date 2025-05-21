import app/auth
import context/base.{type Context}
import gleam/string_tree
import views/components/home
import views/index
import wisp.{type Response}

pub fn protected_route(req, ctx: Context, next: fn() -> Response) -> Response {
  let is_authorized =
    auth.check_cookies(req, wisp.get_secret_key_base(req), ctx)

  let index = index.index(home.redirect_to_login, ctx)
  case is_authorized {
    Ok(Nil) -> next()
    _ -> wisp.html_response(string_tree.from_string(index), 401)
  }
}
