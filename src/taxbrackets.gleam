import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// Model 
pub type Model =
  Option(Int)

// Msg 
pub type Msg {
  Change(String)
}

// init 

fn init(_flags) -> Model {
  Some(0)
}

// update 
// ignores " ", "$", and ",", and ignores everything 
// after the decimal point
fn update(_model: Model, msg: Msg) -> Model {
  let res = case msg {
    Change(s) ->
      s
      |> string.replace("$", "")
      |> string.replace(",", "")
      |> string.replace(" ", "")
  }
  let strnum = case string.split_once(res, ".") {
    Ok(#(a, _)) -> a
    Error(_) -> res
  }
  case int.parse(strnum) {
    Ok(i) -> Some(i)
    Error(_) -> None
  }
}

// view
fn view(model: Model) -> element.Element(Msg) {
  html.div([attribute.class("columns")], [
    html.div([attribute.class("column")], [
      html.div([attribute.class("tabs")], [
        html.ul([], [
          html.li([], [html.a([], [html.text("Background")])]),
          html.li([attribute.class("is-active")], [
            html.a([], [html.text("Calculator")]),
          ]),
        ]),
      ]),
      html.div([attribute.class("field")], [
        html.label([attribute.class("label")], [html.text("Income")]),
        html.div([attribute.class("control")], [
          html.input([
            attribute.class("button is-primary is-outlined"),
            attribute.value("$" <> option.unwrap(model, 0) |> format_number()),
            event.on_input(Change),
          ]),
        ]),
        html.p([attribute.class("help")], [html.text("Input number above.")]),
      ]),
      html.div([attribute.class("field")], [
        html.label([attribute.class("label")], [html.text("Taxable Income")]),
        html.div([attribute.class("control")], [
          html.input([
            attribute.class("button is-link"),
            attribute.disabled(True),
            attribute.value(case model {
              Some(s) ->
                s
                |> calculate_taxable_income(standarddeduction2023single)
                |> format_number()
                |> fn(x) { "$" <> x }
              None -> "Invalid Input"
            }),
            event.on_input(Change),
          ]),
        ]),
      ]),
      html.div([attribute.class("field")], [
        html.label([attribute.class("label")], [html.text("Federal Income Tax")]),
        html.div([attribute.class("control")], [
          html.input([
            attribute.class("button is-info"),
            attribute.disabled(True),
            attribute.value(case model {
              Some(s) ->
                s
                |> calculate_taxable_income(standarddeduction2023single)
                |> calculate_taxes(taxbracket2023single)
                |> format_number()
                |> fn(x) { "$" <> x }
              None -> "Invalid Input"
            }),
            event.on_input(Change),
          ]),
        ]),
      ]),
      html.div([attribute.class("field")], [
        html.label([attribute.class("label")], [html.text("Effective Tax Rate")]),
        html.div([attribute.class("control")], [
          html.input([
            attribute.class("button is-warning"),
            attribute.disabled(True),
            attribute.value(case model {
              Some(s) ->
                {
                  s
                  |> calculate_effective_tax_rate(
                    standarddeduction2023single,
                    taxbracket2023single,
                  )
                  |> format_percentage()
                }
                <> "%"
              None -> "Invalid Input"
            }),
            event.on_input(Change),
          ]),
        ]),
      ]),
    ]),
  ])
  //     ]
  //           [
  //             html.div(
  //               case model {
  //                 Some(_) -> []
  //                 None -> [attribute.style([#("color", "red")])]
  //               },
  //               [html.text("Input numbers only")],
  //             ),
  //           ],
  //         ),
  //         ui.field(
  //           [],
  //           [html.text("Taxable Income")],
  //           ui.button([], [
  //             html.text(case model {
  //               Some(s) ->
  //                 s
  //                 |> calculate_taxable_income(standarddeduction2023single)
  //                 |> format_number()
  //                 |> fn(x) { "$" <> x }
  //               None -> "Invalid Input"
  //             }),
  //           ]),
  //           [],
  //         ),
  //         ui.field(
  //           [],
  //           [html.text("Federal Income Tax")],
  //           ui.button([], [
  //             html.text(case model {
  //               Some(s) ->
  //                 s
  //                 |> calculate_taxable_income(standarddeduction2023single)
  //                 |> calculate_taxes(taxbracket2023single)
  //                 |> format_number()
  //                 |> fn(x) { "$" <> x }
  //               None -> "Invalid Input"
  //             }),
  //           ]),
  //           [],
  //         ),
  //         ui.field(
  //           [],
  //           [html.text("Effective Tax Rate")],
  //           ui.button([], [
  //             html.text(case model {
  //               Some(s) ->
  //                 {
  //                   s
  //                   |> calculate_effective_tax_rate(
  //                     standarddeduction2023single,
  //                     taxbracket2023single,
  //                   )
  //                   |> format_percentage()
  //                 }
  //                 <> "%"
  //               None -> "Invalid Input"
  //             }),
  //           ]),
  //           [],
  //         ),
  //       ]),
  //     ]),
  //   ),
  // )
}

// number formatting
pub fn format_percentage(n: Float) -> String {
  let rawnumberstring =
    n *. 1000.0
    |> float.round
    |> int.to_string
  let len = string.length(rawnumberstring)
  case len == 1 {
    False -> string.slice(rawnumberstring, 0, len - 1)
    True -> "0"
  }
  <> "."
  <> string.slice(rawnumberstring, len - 1, 1)
}

fn format_number_helper(n: Int, result: List(Int)) -> List(Int) {
  case n < 1000 {
    True -> [n, ..result]
    False -> format_number_helper(n / 1000, [n % 1000, ..result])
  }
}

pub fn format_number(n: Int) -> String {
  let ns =
    format_number_helper(n, [])
    |> list.map(int.to_string)
  case ns {
    [] -> ""
    [head] -> head
    [head, ..rest] ->
      rest
      |> list.map(fn(x) { string.pad_start(x, 3, "0") })
      |> fn(x) { [head, ..x] }
      |> string.join(",")
  }
}

// business logic 
pub type BracketRate =
  #(Int, Int)

pub type Brackets =
  List(BracketRate)

pub const taxbracket2023single: Brackets = [
  #(37, 578_120), #(35, 231_250), #(32, 182_100), #(24, 95_375), #(22, 44_725),
  #(12, 11_000), #(10, 0),
]

pub const standarddeduction2023single: Int = 13_850

pub fn take_percentage(number: Int, percentage: Int) -> Int {
  let wholenumber = number * percentage
  let mainnumber =
    int.divide(wholenumber, 100)
    |> result.unwrap(0)
  let rem =
    int.remainder(wholenumber, 100)
    |> result.unwrap(0)
  case rem >= 50 {
    True -> mainnumber + 1
    False -> mainnumber
  }
}

fn calculate_taxes_helper(taxable_income: Int, bracket: Brackets) -> #(Int, Int) {
  let reducer = fn(last_result, next_bracket) {
    case next_bracket, last_result {
      #(bracket_rate, bracket_max_income), #(income, taxes) ->
        case income > bracket_max_income {
          True -> #(
            bracket_max_income,
            taxes + take_percentage(income - bracket_max_income, bracket_rate),
          )
          False -> #(income, taxes)
        }
    }
  }
  list.fold(bracket, #(taxable_income, 0), reducer)
}

pub fn calculate_taxable_income(income: Int, deduction: Int) -> Int {
  int.max(income - deduction, 0)
}

pub fn calculate_taxes(taxable_income: Int, bracket: Brackets) -> Int {
  case calculate_taxes_helper(taxable_income, bracket) {
    #(_, t) -> t
  }
}

pub fn calculate_effective_tax_rate(
  income: Int,
  deduction: Int,
  bracket: Brackets,
) -> Float {
  let taxable_income = int.max(income - deduction, 0)
  int.to_float(calculate_taxes(taxable_income, bracket)) /. int.to_float(income)
}
