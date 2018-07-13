require "../src/orderbook/fill"
require "faker"
require "./spec_helper"
require "spec2"

Spec2.describe "Fill" do
  it "write method testing" do
    fee = Faker::Commerce.price.to_f64
    side_fee = Faker::Commerce.price.to_f64

    fill = Fill.new(
      create_fake_order("bid"),
      create_fake_order(),
      Faker::Commerce.price.to_f64,
      Faker::Commerce.price.to_f64,
      true
    )

    fill.write

    expect(fill.fee).to eq (fill.amount * Fill::TAKER_COM_FEE)
    expect(fill.side_fee).to eq (fill.amount * Fill::TAKER_COM_FEE)
  end
end
