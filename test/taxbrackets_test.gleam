import gleeunit
import gleeunit/should
import taxbrackets

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn take_percentage_test() {
  taxbrackets.take_percentage(100, 10)
  |> should.equal(10)

  taxbrackets.take_percentage(100, 7)
  |> should.equal(7)

  taxbrackets.take_percentage(150, 50)
  |> should.equal(75)
}

pub fn calculate_taxes_test() {
  taxbrackets.calculate_taxes(100, taxbrackets.taxbracket2023single)
  |> should.equal(10)

  taxbrackets.calculate_taxes(11_000, taxbrackets.taxbracket2023single)
  |> should.equal(1100)

  taxbrackets.calculate_taxes(11_500, taxbrackets.taxbracket2023single)
  |> should.equal(1160)
}

pub fn format_percentage_test() {
  taxbrackets.format_percentage(0.05)
  |> should.equal("5.0")

  taxbrackets.format_percentage(0.0774)
  |> should.equal("7.7")

  taxbrackets.format_percentage(1.0)
  |> should.equal("100.0")
}

pub fn format_number_test() {
  taxbrackets.format_number(1)
  |> should.equal("1")

  taxbrackets.format_number(100)
  |> should.equal("100")

  taxbrackets.format_number(1234)
  |> should.equal("1,234")
}

pub fn tax_rate_test() {
  taxbrackets.calculate_taxable_income(
    195_950,
    taxbrackets.standarddeduction2023single,
  )
  |> taxbrackets.calculate_taxes(taxbrackets.taxbracket2023single)
  |> should.equal(37_104)

  taxbrackets.calculate_taxable_income(
    245_100,
    taxbrackets.standarddeduction2023single,
  )
  |> taxbrackets.calculate_taxes(taxbrackets.taxbracket2023single)
  |> should.equal(52_832)

  taxbrackets.calculate_taxable_income(
    1_000_000,
    taxbrackets.standarddeduction2023single,
  )
  |> taxbrackets.calculate_taxes(taxbrackets.taxbracket2023single)
  |> should.equal(325_208)
}
