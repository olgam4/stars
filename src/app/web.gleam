import app/context.{type Context}
import gleam/bool
import gleam/http.{Get, Head, Options}
import gleam/http/request
import gleam/http/response
import gleam/result
import gleam/string
import wisp

const csrf_token = "68M7_Q89mS6nuG7L1X2ZwBrWVUT72Y4d"

pub fn middleware(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  use <- csrf_token_middleware(req)
  use <- add_cache_to_styles(req)
  use <- add_cache_to_lib(req)

  use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)

  handle_request(req)
}

pub fn csrf_token_middleware(req: wisp.Request, next handler) {
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
