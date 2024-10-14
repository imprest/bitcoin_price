import gleam/dynamic
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import lustre_http

pub type Model {
  Model(current_price: String)
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(Model("Not Asked"), effect.none())
}

pub type Msg {
  UserGetPrice
  ApiReturnedPrice(Result(String, lustre_http.HttpError))
}

pub fn update(_model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    UserGetPrice -> #(Model("Loading..."), get_price())
    ApiReturnedPrice(Ok(price)) -> #(Model(price <> " USD"), effect.none())
    ApiReturnedPrice(Error(_)) -> #(
      Model("Error in http fetch."),
      effect.none(),
    )
  }
}

fn get_price() -> effect.Effect(Msg) {
  let decoder =
    dynamic.field("rate", dynamic.string)
    |> dynamic.field("USD", _)
    |> dynamic.field("bpi", _)

  let expect = lustre_http.expect_json(decoder, ApiReturnedPrice)

  lustre_http.get("http://api.coindesk.com/v1/bpi/currentprice.json", expect)
}

pub fn view(model: Model) -> element.Element(Msg) {
  html.div([], [
    html.p([], [
      html.h1([], [element.text("Bitcoin Price")]),
      html.h5([], [element.text("It costs right now:")]),
    ]),
    html.p([attribute.class("alert alert-success")], [
      html.h4([attribute.class("text-success mb-0 p-2")], [
        element.text(model.current_price),
      ]),
    ]),
    html.button(
      [attribute.class("btn btn-outline-primary"), event.on_click(UserGetPrice)],
      [element.text("Update it now")],
    ),
  ])
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
