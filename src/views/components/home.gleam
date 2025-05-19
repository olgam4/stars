import nakai/attr
import nakai/html

pub fn body() -> html.Node {
  html.Fragment([
    html.input([attr.Attr("data-bind-input", "")]),
    html.p_text([attr.Attr("data-text", "$input")], ""),
    html.button_text(
      [attr.Attr("data-on-click", "@post('/heartbeat')")],
      "Post heartbeat",
    ),
    html.button_text(
      [attr.Attr("data-on-click", "@get('/heartbeat')")],
      "Get heartbeat",
    ),
  ])
}

pub fn redirect_to_login() -> html.Node {
  html.Fragment([
    html.div_text([attr.Attr("data-on-load", "window.location = '/login'")], ""),
  ])
}
