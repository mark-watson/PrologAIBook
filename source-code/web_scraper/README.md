# Web Scraper

HTML parsing and structured data extraction using SGML and XPath. Companion code for the Web Clients chapter.

## Running Examples

```shell
swipl -s load.pl
```

```prolog
?- fetch_page('https://example.com', DOM), extract_links(DOM, Links).
```

## Running Tests

```shell
swipl -g "['tests/test_scraper.pl'], run_tests, halt" -s load.pl
```

## Description

Combines SWI-Prolog's HTTP client with `library(sgml)` and `library(xpath)` to fetch web pages, parse HTML into DOM trees, and extract links and text content using XPath expressions.
