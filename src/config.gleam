import gleam/list
import simplifile
import tom

pub type Config {
  Config(name: String, from: Int, to: Int, private: Bool, webhook: String)
}

pub fn read_config() -> List(Config) {
  let assert Ok(config) =
    simplifile.read("/home/sakura/.config/gleamanzeigen/config.toml")
  let assert Ok(parsed) = tom.parse(config)

  let assert Ok(parsed_list) = tom.get_array(parsed, ["products"])
  parsed_list
  |> list.map(fn(p) {
    let assert Ok(dict) = tom.as_table(p)
    dict
  })
  |> list.map(fn(d) {
    let assert Ok(name) = tom.get_string(d, ["name"])
    let assert Ok(from) = tom.get_int(d, ["from"])
    let assert Ok(to) = tom.get_int(d, ["to"])

    let assert Ok(private) = tom.get_bool(d, ["private"])
    let assert Ok(webhook) = tom.get_string(d, ["webhook"])
    Config(name, from, to, private, webhook)
  })
}
