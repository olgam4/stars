import nakai
import nakai/attr
import nakai/html

const csrf_token = "68M7_Q89mS6nuG7L1X2ZwBrWVUT72Y4d"

pub fn index(children) {
  html.Html([attr.lang("fr-CA")], [
    html.Head([
      html.meta([attr.name("csrf-token"), attr.content(csrf_token)]),
      html.meta([
        attr.name("viewport"),
        attr.content("width=device-width, initial-scale=1.0"),
      ]),
      html.meta([attr.http_equiv("Content-Security-Policy"), attr.content("default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline'")]),
      html.link([attr.rel("stylesheet"), attr.href("/static/reset.css")]),
      html.link([attr.rel("stylesheet"), attr.href("/static/open-props.css")]),
      html.link([attr.rel("stylesheet"), attr.href("/static/icons.css")]),
    ]),
    html.Body([], [
      children(),
      html.Element(
        "script",
        [attr.src("/static/lib/datastar.js"), attr.type_("module")],
        [],
      ),
      html.Element("script", [attr.src("/static/lib/csrf.js")], []),
    ]),
  ])
  |> nakai.to_string()
}
