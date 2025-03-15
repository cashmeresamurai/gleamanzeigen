import config
import gleam/erlang/process
import gleam/list
import gleam/otp/task
import klaz
import parser
import webhook

pub fn main() {
  let configs = config.read_config()

  configs
  |> list.map(fn(c) { task.async(fn() { loop(c, []) }) })
  |> list.each(task.await_forever)
}

fn loop(config: config.Config, seen: List(String)) {
  let assert Ok(html) = klaz.get_html(config)
  let assert Ok(ad) =
    parser.parser(html)
    |> parser.ad_from_json
    |> echo

  case list.contains(seen, ad.title) {
    False -> {
      webhook.webhook(ad, config.webhook)
      process.sleep(300_000)
      loop(config, [ad.title, ..seen])
    }
    True -> {
      process.sleep(300_000)
      loop(config, [ad.title, ..seen])
    }
  }
}
