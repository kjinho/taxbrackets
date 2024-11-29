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
  Definitions
  Calculator
  Bibliography
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
  html.div([attribute.class("container")], [
    view_tabs(model),
    html.div([attribute.class("columns")], [
      html.div([attribute.class("column")], [
        case model.tab {
          Background -> view_background(model)
          Definitions -> view_definitions(model)
          Calculator -> view_calculator_instructions(model)
          Bibliography -> view_bibliography(model)
        },
      ]),
      html.div([attribute.class("column is-one-third")], [
        view_calculator_calc(model),
      ]),
    ]),
  ])
}

fn view_tabs(model: Model) -> element.Element(Msg) {
  html.div([attribute.class("tabs")], [
    html.ul([], case model.tab {
      Background -> [
        html.li([attribute.class("is-active")], [
          html.a([event.on_click(TabSwitch(Background))], [
            html.text("Background"),
          ]),
        ]),
        html.li([attribute.class("is-inactive")], [
          html.a([event.on_click(TabSwitch(Definitions))], [
            html.text("Definitions"),
          ]),
        ]),
        html.li([attribute.class("is-inactive")], [
          html.a([event.on_click(TabSwitch(Calculator))], [
            html.text("Calculator"),
          ]),
        ]),
        html.li([attribute.class("is-inactive")], [
          html.a([event.on_click(TabSwitch(Bibliography))], [
            html.text("Bibliography"),
          ]),
        ]),
      ]
      Definitions -> [
        html.li([attribute.class("is-inactive")], [
          html.a([event.on_click(TabSwitch(Background))], [
            html.text("Background"),
          ]),
        ]),
        html.li([attribute.class("is-active")], [
          html.a([event.on_click(TabSwitch(Definitions))], [
            html.text("Definitions"),
          ]),
        ]),
        html.li([attribute.class("is-inactive")], [
          html.a([event.on_click(TabSwitch(Calculator))], [
            html.text("Calculator"),
          ]),
        ]),
        html.li([attribute.class("is-inactive")], [
          html.a([event.on_click(TabSwitch(Bibliography))], [
            html.text("Bibliography"),
          ]),
        ]),
      ]
      Calculator -> [
        html.li([attribute.class("is-inactive")], [
          html.a([event.on_click(TabSwitch(Background))], [
            html.text("Background"),
          ]),
        ]),
        html.li([attribute.class("is-inactive")], [
          html.a([event.on_click(TabSwitch(Definitions))], [
            html.text("Definitions"),
          ]),
        ]),
        html.li([attribute.class("is-active")], [
          html.a([event.on_click(TabSwitch(Calculator))], [
            html.text("Calculator"),
          ]),
        ]),
        html.li([attribute.class("is-inactive")], [
          html.a([event.on_click(TabSwitch(Bibliography))], [
            html.text("Bibliography"),
          ]),
        ]),
      ]
      Bibliography -> [
        html.li([attribute.class("is-inactive")], [
          html.a([event.on_click(TabSwitch(Background))], [
            html.text("Background"),
          ]),
        ]),
        html.li([attribute.class("is-inactive")], [
          html.a([event.on_click(TabSwitch(Definitions))], [
            html.text("Definitions"),
          ]),
        ]),
        html.li([attribute.class("is-inactive")], [
          html.a([event.on_click(TabSwitch(Calculator))], [
            html.text("Calculator"),
          ]),
        ]),
        html.li([attribute.class("is-active")], [
          html.a([event.on_click(TabSwitch(Bibliography))], [
            html.text("Bibliography"),
          ]),
        ]),
      ]
    }),
  ])
}

fn view_background(_model: Model) -> element.Element(Msg) {
  html.div([attribute.class("content")], [
    html.h3([], [html.text("Understanding Tax Brackets")]),
    html.p([], [
      html.text(
        "There are several common misconceptions about 
      the federal income tax system in the United States:",
      ),
      html.ul(
        [],
        list.map(
          [
            "Having income at a certain tax bracket 
                        means that your entire income is taxed at 
                        that tax bracket.",
            "Stepping up into the next tax bracket 
                        can result in a much higher income tax 
                        and therefore a lower net income.",
          ],
          fn(x) { html.li([], [html.text(x)]) },
        ),
      ),
      html.text(
        "Both of these misconceptions are false. This 
                calculator attempts to illustrate how and why.",
      ),
    ]),
    html.p([], [
      html.text(
        "Federal income tax is \"progressive,\"
                meaning that the tax rate is higher 
                for higher levels of income. 
                In other words, the federal government 
                taxes higher income at higher rates.
                To implement this progressive tax, 
                the federal government publishes 
                a set of tax brackets.",
      ),
    ]),
    html.p([], [
      html.text("Notably, "),
      html.em([], [
        html.text(
          "the tax rate only 
                    applies to the income within each 
                    range.",
        ),
      ]),
      html.text(
        "
                In other words, if a taxpayer's taxable income 
                is $40,000, the taxpayer only pays 
                the 12% tax rate on their taxable income from 
                $11,001 to $40,000. The remaining $11,000
                of their income is taxed at the lower 
                tax rate of 10%. Consequently, the total 
                federal income tax that the taxpayer 
                owes is only $4,580, which is approximately
                11.5% of their total taxable income of $40,000.",
      ),
    ]),
    html.p([], [
      html.text(
        "Even better for the taxpayer, not all of 
                their income is taxable. The tax law 
                allows certain deductions to reduce a taxpayer's 
                taxable income. For most taxpayers, the so-called 
                \"standard deduction\" is both the easiest and largest 
                available deduction to their taxable income. 
                For tax year 2023, the standard deduction is 
                $13,850. For most taxpayers, that means they can
                subtract $13,850 from their total income before they 
                start applying the tax rates from the tax brackets.
                For the example above, the taxpayer would be able 
                to have a total income of $53,850 yet ",
      ),
      html.em([], [
        html.text(
          "still 
                    be taxed only on $40,000 of their income",
        ),
      ]),
      html.text(
        "because of the standard deduction. Consequently,
                their federal income tax of $4,580 is only 
                approximately 8.5% of their total income. This 
                8.5% is the so-called \"effective\" tax rate.",
      ),
    ]),
    html.p([], [
      html.text(
        "A progressive tax system like this results in a 
                much lower tax burden that most taxpayers expect. 
                Unfortunately, the amount of math it takes to 
                understand how much your taxes are results in the 
                misconceptions stated above.",
      ),
    ]),
    html.p([], [
      html.text(
        "To ease this problem, you can use this calculator to estimate "
        <> "your federal income tax and effective tax rate. To keep things "
        <> "simple, the calculator uses the tax rates for a single filer "
        <> "using the standard deduction. Married people filing jointly, "
        <> "people with significant itemized deductions, and people able to "
        <> "take advantage of tax credits (such as the "
        <> "earned income credit, child tax credit, etc.) may "
        <> "owe even less in taxes and have an even lower effective "
        <> "tax rate.",
      ),
    ]),
  ])
}

fn definition_helper(word: String, definition: String) -> element.Element(Msg) {
  html.li([], [
    html.b([attribute.class("is-uppercase")], [html.text(word <> ": ")]),
    html.text(definition),
  ])
}

fn view_definitions(_model: Model) -> element.Element(Msg) {
  html.div([attribute.class("content")], [
    html.div([attribute.class("title is-4")], [html.text("Definitions")]),
    html.ul([], [
      definition_helper(
        "Effective Tax Rate",
        "The taxpayer's actual tax burden as a percentage of the 
        taxpayer's total income.",
      ),
      definition_helper(
        "Taxable Income",
        "The portion of a taxpayer's income that the 
      federal government uses to calculate tax owed.",
      ),
    ]),
  ])
}

fn view_bibliography(_model: Model) -> element.Element(Msg) {
  html.div([attribute.class("container")], [
    //html.h2([attribute.class("title is-3")], [html.text("Works Cited")]),
    html.div([attribute.class("content")], [
      html.ul([], [
        html.li([], [
          html.a(
            [
              attribute.href(
                "https://www.irs.gov/filing/federal-income-tax-rates-and-brackets",
              ),
            ],
            [html.text("IRS, Federal income tax and brackets, Oct. 16, 2024.")],
          ),
        ]),
        html.li([], [
          html.a(
            [attribute.href("https://www.irs.gov/publications/p17#d0e50213")],
            [
              html.text(
                "IRS, \"Tax Tables,\" Your Federal Income Tax: For Individuals, Publication 17 (2023).",
              ),
            ],
          ),
        ]),
      ]),
    ]),
  ])
}

// fn view_calculator(model: Model) -> element.Element(Msg) {
//   html.div([attribute.class("columns")], [
//     html.div([attribute.class("column")], [view_calculator_instructions(model)]),
//     html.div([attribute.class("column is-one-third")], [
//       view_calculator_calc(model),
//     ]),
//   ])
// }

fn view_calculator_instructions(_model: Model) -> element.Element(Msg) {
  html.div([attribute.class("content")], [
    html.div([attribute.class("title is-4")], [html.text("Directions")]),
    html.p([], [
      html.text(
        "To estimate the taxable income, federal income tax, and 
        effective tax rate for a single filer using the standard 
        deduction for tax year 2023:",
      ),
    ]),
    html.ul(
      [],
      list.map(
        [
          "Enter your total annual income in the \"Income\" field.",
          "The remaining fields will automatically update as you 
          enter your income.",
        ],
        fn(x) { html.li([], [html.text(x)]) },
      ),
    ),
  ])
}

fn view_calculator_calc(model: Model) -> element.Element(Msg) {
  html.div([attribute.class("container")], [
    html.div([attribute.class("title is-4")], [html.text("Tax Calculator")]),
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
