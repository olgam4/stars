import nakai/attr
import nakai/html

pub fn body() -> html.Node {
  html.Fragment([
    html.div([attr.Attr("data-on-load", "@get('/api/events')")], []),
    html.div([attr.id("mama")], []),
    html.button_text(
      [attr.Attr("data-on-click", "@post('/api/component')")],
      "Send",
    ),
  ])
}
