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
pub type Tab {
  Background
  Calculator
}

pub type Model {
  Model(income: Option(Int), tab: Tab)
}

// Msg 
pub type Msg {
  Change(String)
  TabSwitch(Tab)
}

// init 

fn init(_flags) -> Model {
  Model(income: Some(0), tab: Calculator)
}

// update 
// ignores " ", "$", and ",", and ignores everything 
// after the decimal point
fn update(model: Model, msg: Msg) -> Model {
  case msg {
    TabSwitch(x) -> Model(..model, tab: x)
    Change(s) -> Model(..model, income: change_string_helper(s))
  }
}

fn change_string_helper(s: String) -> Option(Int) {
  let res =
    s
    |> string.replace("$", "")
    |> string.replace(",", "")
    |> string.replace(" ", "")
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
      view_tabs(model),
      case model.tab {
        Background -> view_background(model)
        Calculator -> view_calculator(model)
      },
    ]),
  ])
}

fn view_tabs(model: Model) -> element.Element(Msg) {
  html.div([attribute.class("tabs")], [
    html.ul([], [
      html.li(
        [
          case model.tab {
            Background -> attribute.class("is-active")
            _ -> attribute.class("is-inactive")
          },
        ],
        [
          html.a([event.on_click(TabSwitch(Background))], [
            html.text("Background"),
          ]),
        ],
      ),
      html.li(
        [
          case model.tab {
            Calculator -> attribute.class("is-active")
            _ -> attribute.class("is-inactive")
          },
        ],
        [
          html.a([event.on_click(TabSwitch(Calculator))], [
            html.text("Calculator"),
          ]),
        ],
      ),
    ]),
  ])
}

fn view_background(_model: Model) -> element.Element(Msg) {
  html.div([attribute.class("container")], [
    html.p([], [
      html.text(
        "You can use this form to estimate your federal income tax "
        <> "and effective tax rate. To keep things simple, the form "
        <> "uses the tax rates for a single filer using the standard "
        <> "deduction. Married people filing jointly, people with "
        <> "significant itemized deductions, people able to "
        <> "take advantage of tax credits (such as the "
        <> "earned income credit, child tax credit, etc.) may "
        <> "owe even less in taxes and have an even lower effective "
        <> "tax rate.",
      ),
    ]),
  ])
}

fn view_calculator(model: Model) -> element.Element(Msg) {
  html.div([attribute.class("container")], [
    html.div([attribute.class("field")], [
      html.label([attribute.class("label")], [html.text("Income")]),
      html.div([attribute.class("control")], [
        html.input([
          attribute.class("button is-primary is-outlined"),
          attribute.value(
            "$" <> option.unwrap(model.income, 0) |> format_number(),
          ),
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
          attribute.value(case model.income {
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
          attribute.value(case model.income {
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
          attribute.value(case model.income {
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
  ])
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
