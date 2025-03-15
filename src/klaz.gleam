import gleam/http.{Get}
import config
import gleam/http/request.{set_header, set_method}
import gleam/httpc
import gleam/io
import gleam/result
import gleam/string

// makes response and returns html string of searched value
pub fn get_html(config: config.Config) -> Result(String, httpc.HttpError) {
  let url = case config.private {
    False ->
      string.concat([
        "https://www.kleinanzeigen.de/s-preis:",
        string.inspect(config.from),
        ":",
        string.inspect(config.to),
        "/",
        config.name,
        "/k0",
      ])
    True ->
      string.concat([
        "https://www.kleinanzeigen.de/s-anbieter:privat/",
        "preis:",
        string.inspect(config.from),
        ":",
        string.inspect(config.to),
        "/",
        config.name,
        "/k0",
      ])
  }
  io.debug(url)
  let assert Ok(base_req) = request.to(url)

  let req =
    base_req
    |> set_method(Get)
    |> set_header("User-Agent", "")
    |> set_header(
      "Accept",
      "ext/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
    )
  // |> request.set_body(params)
  use resp <- result.try(httpc.send(req))
  Ok(resp.body)
}
