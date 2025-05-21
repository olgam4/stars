import context/base.{type Context}
import gleam/bool
import gleam/http.{Get, Head, Options}
import gleam/http/request
import gleam/http/response
import gleam/result
import gleam/string
import wisp

pub fn middleware(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  use <- csrf_token_middleware(req, ctx.csrf_token)
  use <- add_cache_to_styles(req)
  use <- add_cache_to_lib(req)


  handle_request(req)
}

pub fn csrf_token_middleware(req: wisp.Request, csrf_token, next handler) {
  case req.method {
    Get | Head | Options -> handler()
    _ -> {
      let csrf_value =
        result.unwrap(request.get_header(req, "x-csrf-token"), "")
      use <- bool.guard(csrf_value != csrf_token, return: wisp.bad_request())

      handler()
    }
  }
}

fn add_cache_to_styles(req: wisp.Request, handler) -> wisp.Response {
  case string.ends_with(req.path, ".css") {
    False -> handler()
    _ ->
      handler()
      |> response.prepend_header("cache-control", "public, max-age=31536000")
  }
}

fn add_cache_to_lib(req: wisp.Request, handler) -> wisp.Response {
  case string.starts_with(req.path, "/static/lib/") {
    False -> handler()
    _ ->
      handler()
      |> response.prepend_header("cache-control", "public, max-age=31536000")
  }
}
