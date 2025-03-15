use soup::{NodeExt, QueryBuilderExt, Soup};

pub fn get_title(html: String) -> String {
    let soup = Soup::new(&html);
    soup.tag("li")
        .attr("class", "ad-listitem")
        .find()
        .and_then(|article| article.tag("a").attr("class", "ellipsis").find())
        .map(|title| title.text())
        .unwrap_or_default()
        .trim()
        .to_string()
}

pub fn get_url(html: String) -> String {
    let soup = Soup::new(&html);
    soup.tag("li")
        .attr("class", "ad-listitem")
        .find()
        .and_then(|article| article.tag("a").attr("class", "ellipsis").find())
        .and_then(|a| a.get("href"))
        .unwrap_or_default()
        .trim()
        .to_string()
}

pub fn get_price(html: String) -> String {
    let soup = Soup::new(&html);
    soup.tag("li")
        .attr("class", "ad-listitem")
        .find()
        .and_then(|article| {
            article
                .tag("p")
                .attr("class", "aditem-main--middle--price-shipping--price")
                .find()
        })
        .map(|price| price.text())
        .unwrap_or_default()
        .trim()
        .to_string()
}
