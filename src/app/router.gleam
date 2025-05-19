import app/context.{type Context}
import app/datastar_utils
import app/router/auth
import app/router/protected.{protected_route}
import app/router/user
import app/sse
import app/web
import datastar
import gleam/erlang/process
import gleam/http.{Get}
import gleam/string_tree
import gleam/time/duration
import gleam/time/timestamp
import views/components/home
import views/components/login
import views/components/sse_view
import views/index
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)

  case wisp.path_segments(req) {
    [] -> home_page(req, ctx)
    ["heartbeat"] -> heartbeat()
    ["login"] -> login_page(req)
    ["sse"] -> sse_page(req, ctx)
    ["api", "component"] -> component(req, ctx)
    ["api", "user"] -> user.user_router(req, ctx)
    ["api", "login"] -> auth.login(req, ctx)
    _ -> wisp.not_found()
  }
}

fn heartbeat() {
  let now =
    timestamp.system_time()
    |> timestamp.to_rfc3339(duration.hours(0))

  wisp.ok()
  |> wisp.string_body(now)
}

fn sse_page(req, ctx) {
  use <- wisp.require_method(req, Get)
  use <- protected_route(req, ctx)

  let index = index.index(sse_view.body)
  wisp.html_response(string_tree.from_string(index), 200)
}

fn component(req, ctx: context.Context) {
  use <- protected_route(req, ctx)

  let pubsub = ctx.pubsub
  let events =
    [
      datastar.merge_fragments("<div>Hello</div>")
      |> datastar.merge_fragments_selector("#mama")
      |> datastar.merge_fragments_merge_mode(datastar.Append)
      |> datastar.merge_fragments_end(),
    ]
    |> datastar.events_to_string
    |> datastar_utils.sanitize

  let message = sse.Publish(events)
  process.send(pubsub, message)

  wisp.ok()
}

fn home_page(req, ctx) {
  use <- wisp.require_method(req, Get)
  use <- protected_route(req, ctx)

  let index = index.index(home.body)
  wisp.html_response(string_tree.from_string(index), 200)
}

fn login_page(req) {
  use <- wisp.require_method(req, Get)

  let index = index.index(login.login)
  wisp.html_response(string_tree.from_string(index), 200)
}
