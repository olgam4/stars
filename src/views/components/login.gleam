import nakai/attr
import nakai/html

pub fn login() -> html.Node {
  html.Fragment([
    html.Head([
      html.link([attr.rel("stylesheet"), attr.href("/static/login.css")]),
    ]),
    html.div([attr.class("login")], [
      html.div([attr.class("container")], [
        html.h1_text([], "login"),
        html.form(
          [
            attr.Attr(
              "data-on-submit",
              "@post('/api/login', {contentType: 'form'})",
            ),
          ],
          [
            html.label([], [
              html.span_text([], "Username"),
              html.input([attr.type_("text"), attr.name("username")]),
            ]),
            html.label([], [
              html.span_text([], "Password"),
              html.input([attr.type_("password"), attr.name("password")]),
            ]),
            html.div([attr.class("actions")], [
              html.button([], [html.i([attr.class("gg-arrow-right")], [])]),
            ]),
          ],
        ),
      ]),
    ]),
  ])
}
