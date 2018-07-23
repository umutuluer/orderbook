require "../src/orderbook"
require "faker"

def create_fake_order(side = "ask", order_type = "limit")
  order = Order.new
  order.id = Faker::Number.number(10).to_i64
  order.user_id = Faker::Number.number(3).to_i32
  order.base = "BTC"
  order.second = "TRY"
  order.order_type = order_type
  order.side = side
  order.amount = 1
  order.price = Faker::Commerce.price
  order.status = 0

  order
end

def create_order(id, user_id, amount, price, side = "ask", order_type = "limit", easy = false, stop = nil)
  order = Order.new
  order.id = id.to_i64
  order.user_id = user_id
  order.base = "BTC"
  order.second = "TRY"
  order.order_type = order_type
  order.side = side
  order.amount = amount.to_f64
  order.price = price.to_f64
  order.easy = false

  if !stop.nil?
    order.stop = stop.to_f64
  end

  order
end

def print_orderbook(orderbook : OrderBook)
  puts "------------------------"
  puts "FILLED-BOOK"
  orderbook.fills.each do |_|
    puts "fill"
  end

  puts "BUYS:"

  if orderbook.asks.size == 0
    puts "Empty"
  end

  orderbook.asks.each do |ask|
    puts "ID: #{ask.id}, Amount: #{ask.amount}"
  end

  puts "SELLS:"

  if orderbook.bids.size == 0
    puts "Empty"
  end

  orderbook.bids.each do |bid|
    puts "ID: #{bid.id}, Amount: #{bid.amount}"
  end
end
