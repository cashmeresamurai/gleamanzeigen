import fmt
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json
import gleam/result
import gleam/string
import parser

fn is_discord_webhook(url: String) -> Bool {
  // Prüft ob "discord.com" in der URL enthalten ist
  string.contains(url, "discord.com")
}

fn to_discord_form_data(anzeige: parser.Ad) -> String {
  json.object([
    #(
      "embeds",
      json.array(
        [
          json.object([
            #("title", json.string(anzeige.title)),
            #("description", json.string(anzeige.price)),
            #("url", json.string(anzeige.url)),
            #("color", json.int(0x42F5A4)),
            // Mintgrüne Akzentfarbe
            #(
              "footer",
              json.object([
                #("text", json.string("gleamanzeigen made by cashmeresamurai")),
              ]),
            ),
          ]),
        ],
        of: fn(element) { element },
      ),
    ),
  ])
  |> json.to_string
}

fn to_matrix_form_data(anzeige: parser.Ad) -> String {
  // Matrix-spezifisches Payload Format
  let html_message =
    fmt.lit("<b>")
    |> fmt.cat(fmt.string())
    |> fmt.cat(fmt.lit("</b>"))
    |> fmt.cat(fmt.lit("</br>"))
    |> fmt.cat(fmt.lit("<b>"))
    |> fmt.cat(fmt.string())
    |> fmt.cat(fmt.lit("</b>"))
    |> fmt.cat(fmt.lit("</br>"))
    |> fmt.cat(fmt.lit("<a href=\"https://kleinanzeigen.de"))
    |> fmt.cat(fmt.string())
    |> fmt.cat(fmt.lit("\">Link zur Anzeige</a>"))
    |> fmt.cat(fmt.lit("</br>"))
    |> fmt.cat(fmt.lit("<i>Gleamanzeigen by lainware</i>"))
    |> fmt.sprintf3(anzeige.title, anzeige.price, anzeige.url)
    |> echo

  json.object([
    #("text", json.string(anzeige.title)),
    #("html", json.string(html_message)),
  ])
  |> json.to_string
}

pub fn webhook(
  anzeige: parser.Ad,
  webhook: String,
) -> Result(Nil, httpc.HttpError) {
  // Wähle das passende Payload-Format basierend auf der URL
  let form_data = case is_discord_webhook(webhook) {
    True -> to_discord_form_data(anzeige)
    False -> to_matrix_form_data(anzeige)
  }

  let assert Ok(base_request) = request.to(webhook)
  let req =
    base_request
    |> request.set_method(http.Post)
    |> request.set_body(form_data)
    |> request.prepend_header("content-type", "application/json")
    |> request.prepend_header("accept", "application/json")

  use resp <- result.try(httpc.send(req))
  Ok(Nil)
}
