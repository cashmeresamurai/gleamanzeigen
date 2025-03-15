import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json

pub fn parser(html: String) -> String {
  let content =
    json.object([#("content", json.string(html))])
    |> json.to_string

  let assert Ok(url) = request.to("http://localhost:50051/parse")
  let req =
    url
    |> request.set_method(http.Post)
    |> request.set_body(content)
    |> request.prepend_header("content-type", "application/json")
    |> request.prepend_header("accept", "application/json")

  let assert Ok(resp) = httpc.send(req)

  resp.body
}

pub type Ad {
  Ad(title: String, price: String, url: String)
}

pub fn ad_from_json(json_string: String) -> Result(Ad, json.DecodeError) {
  let ad_decoder = {
    use title <- decode.field("title", decode.string)
    use price <- decode.field("price", decode.string)
    use url <- decode.field("url", decode.string)
    decode.success(Ad(title:, price:, url:))
  }
  json.parse(from: json_string, using: ad_decoder)
}
