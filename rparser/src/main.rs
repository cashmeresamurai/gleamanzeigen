// src/main.rs
use axum::{
    routing::post,
    Json,
    Router,
    http::StatusCode
};
use rayon::iter::IntoParallelRefIterator;
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use rayon::iter::ParallelIterator;
mod parser;

#[derive(Serialize, Deserialize)]
struct Message {
    content: String,
}

#[derive(Serialize, Debug)]
struct ParserResponse {
    title: String,
    price: String,
    url: String
}

async fn echo_handler(Json(payload): Json<Message>) -> (StatusCode, Json<ParserResponse>) {

    let formatters = [parser::get_title, parser::get_price, parser::get_url];

    let mut parser: Vec<String> = formatters
        .par_iter()
        .map(|f| f(payload.content.clone()))
        .collect();

    let url = parser.pop().unwrap();
    let price = parser.pop().unwrap();
    let title = parser.pop().unwrap();

    let response = ParserResponse {
        title,
        price,
        url
    };
    println!("{:#?}", response);

    (StatusCode::OK, Json(response))
}

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/parse", post(echo_handler));

    let addr = SocketAddr::from(([127, 0, 0, 1], 50051));
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();

    println!("Server running on http://{}", addr);

    axum::serve(listener, app).await.unwrap();
}
