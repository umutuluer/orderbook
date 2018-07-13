require "./spec_helper"
require "../src/orderbook/orderbook"
require "spec2"
require "benchmark"

Spec2.describe "Orderbook" do
  let!(ob) { OrderBook.new }
  let(bid_side) { "bid" }

  it "test sorting order book" do
    # ask
    ob.add_order create_order(1, 100, 1, 6000)
    ob.add_order create_order(2, 101, 0.90, 6001)
    ob.add_order create_order(3, 102, 1.01, 6000)
    ob.add_order create_order(4, 102, 1.05, 5999)
    ob.add_order create_order(8, 103, 1.05, 6001.1)

    # bid
    ob.add_order create_order(5, 104, 1, 6002, bid_side)
    ob.add_order create_order(6, 105, 2, 6003, bid_side)
    ob.add_order create_order(8, 107, 1.02, 6002.1, bid_side)
    ob.add_order create_order(7, 106, 1.02, 6004, bid_side)
    ob.add_order create_order(9, 106, 1.02, 6004.01, bid_side)
    ob.add_order create_order(10, 106, 1.02, 6004.01, bid_side)

    print_orderbook ob
  end

  it "test get_index method" do
    30.times do |i|
      order = create_fake_order
      ob.asks << order
      ob.asks.shuffle
      expect(ob.get_index(order)).to_be > -1
    end
  end

  it "test buy market" do
    # ask
    ob.add_order create_order(1, 100, 1.1, 30500)
    ob.add_order create_order(2, 101, 0.20, 30300)
    ob.add_order create_order(3, 102, 0.8, 30250)

    # bid
    ob.add_order create_order(4, 104, 0.90, 30600, bid_side)
    ob.add_order create_order(5, 105, 0.75, 30700, bid_side)
    ob.add_order create_order(5, 105, 0.20, 31000, bid_side)

    # easy condition is always taker
    ob.add_order create_order(5, 105, 0.75, 30700, bid_side, "market", true)

    print_orderbook ob
  end

  it "test buy limit order" do
    # buy
    ob.add_order create_order(3, 102, 0.8, 30250)
    ob.add_order create_order(1, 100, 1.1, 30500)
    ob.add_order create_order(2, 101, 0.20, 30300)

    # sell
    ob.add_order create_order(4, 104, 0.90, 30600, bid_side)
    ob.add_order create_order(5, 105, 0.75, 30700, bid_side)
    ob.add_order create_order(6, 107, 0.20, 31000, bid_side)

    # buy
    ob.add_order create_order(9, 102, 2.0, 30600)

    # sell
    ob.add_order create_order(10, 203, 1.10, 30600, bid_side)

    print_orderbook ob
  end

  it "test buy limit order partial" do
    # buy
    ob.add_order create_order(1, 100, 1.1, 30500)
    ob.add_order create_order(2, 101, 0.20, 30300)
    ob.add_order create_order(3, 102, 0.8, 30250)

    # sel
    ob.add_order create_order(4, 104, 1, 30600, bid_side)
    ob.add_order create_order(5, 105, 0.75, 30700, bid_side)
    ob.add_order create_order(6, 106, 0.20, 31000, bid_side)

    # market
    ob.add_order create_order(9, 102, 30600, 0, "ask", "market")

    print_orderbook ob
  end

  it "test sell order scenario a" do
    # buy
    ob.add_order create_order(1, 100, 1.1, 30500)
    ob.add_order create_order(2, 101, 0.20, 30300)
    ob.add_order create_order(3, 102, 0.8, 30250)

    # sell
    ob.add_order create_order(4, 104, 0.90, 30600, bid_side)
    ob.add_order create_order(5, 105, 0.75, 30700, bid_side)
    ob.add_order create_order(6, 107, 0.20, 31000, bid_side)

    # it is taker and operation run directly if price is ready in orderbook
    ob.add_order create_order(7, 102, 1.1, 30500, bid_side)

    # it will wait because price is not enough in orderbook because of that it is maker
    # ob.add_order create_order(7, 102, 0.70, 30501, bid_side)

    print_orderbook ob
  end

  it "test sell order scenario b" do
    # buy
    ob.add_order create_order(4, 104, 0.90, 30600, bid_side)
    ob.add_order create_order(5, 105, 0.75, 30700, bid_side)
    ob.add_order create_order(6, 107, 0.20, 31000, bid_side)

    # sell
    ob.add_order create_order(1, 100, 1.1, 30500)
    ob.add_order create_order(2, 101, 0.20, 30300)
    ob.add_order create_order(3, 102, 0.80, 30250)

    ob.add_order create_order(7, 102, 1.50, 30500, bid_side)

    print_orderbook ob
  end

  it "test sell order scenario c" do
    # buy
    ob.add_order create_order(4, 104, 0.90, 30600, bid_side)
    ob.add_order create_order(5, 105, 0.75, 30700, bid_side)
    ob.add_order create_order(6, 107, 0.20, 31000, bid_side)

    # sell
    ob.add_order create_order(1, 100, 1.1, 30500)
    ob.add_order create_order(2, 101, 0.20, 30300)
    ob.add_order create_order(3, 102, 0.80, 30250)

    ob.add_order create_order(7, 102, 1.20, 0, bid_side, "market")

    print_orderbook ob
  end

  it "test sell order scenario d" do
    # buy
    ob.add_order create_order(4, 104, 0.90, 30600, bid_side)
    ob.add_order create_order(5, 105, 0.75, 30700, bid_side)
    ob.add_order create_order(6, 107, 0.20, 31000, bid_side)

    # sell
    ob.add_order create_order(1, 100, 1.1, 30500)
    ob.add_order create_order(2, 101, 0.20, 30300)
    ob.add_order create_order(3, 102, 0.80, 30250)

    ob.add_order create_order(7, 102, 1, 30550, bid_side)

    print_orderbook ob
  end

  it "test stop market sell scenario a" do
    # buy
    ob.add_order create_order(1, 100, 1.1, 30500)
    ob.add_order create_order(2, 101, 0.20, 30300)
    ob.add_order create_order(3, 102, 0.80, 30250)
    ob.add_order create_order(9, 102, 0.80, 30250)

    # sell
    ob.add_order create_order(4, 104, 0.90, 30600, bid_side)
    ob.add_order create_order(5, 105, 0.75, 30700, bid_side)
    ob.add_order create_order(6, 107, 0.20, 31000, bid_side)

    # stop 30.400
    ob.add_order create_order(7, 104, 1.01, 0, bid_side, "market", false, 30400)
    ob.add_order create_order(10, 104, 0.5, 0, bid_side, "market", false, 30400)

    ob.add_order create_order(8, 100, 1.1, 0, bid_side, "market")

    print_orderbook ob
  end

  it "test stop market sell scenario b" do
    # buy
    ob.add_order create_order(1, 100, 1.1, 30500)
    ob.add_order create_order(2, 101, 0.20, 30300)
    ob.add_order create_order(3, 102, 0.80, 30250)
    ob.add_order create_order(9, 102, 0.80, 30250)

    # sell
    ob.add_order create_order(4, 104, 0.90, 30600, bid_side)
    ob.add_order create_order(5, 105, 0.75, 30700, bid_side)
    ob.add_order create_order(6, 107, 0.20, 31000, bid_side)

    # stop 30.400
    ob.add_order create_order(7, 104, 1.0, 30300, bid_side, "limit", false, 30400)

    ob.add_order create_order(8, 100, 1.1, 0, bid_side, "market")

    print_orderbook ob
  end

  it "test stop market buy" do
    # buy
    ob.add_order create_order(1, 100, 1.1, 30500)
    ob.add_order create_order(2, 101, 0.20, 30300)
    ob.add_order create_order(3, 102, 0.80, 30250)

    # sell
    ob.add_order create_order(4, 104, 0.90, 30600, bid_side)
    ob.add_order create_order(5, 105, 0.75, 30700, bid_side)
    ob.add_order create_order(6, 107, 0.20, 31000, bid_side)

    # stop 30.400
    ob.add_order create_order(7, 104, 1, 0, "ask", "market", true, 30900)

    ob.add_order create_order(8, 100, 1.1, 0, "ask", "market")

    print_orderbook ob
  end

  # it "test benchmark market" do
  #   n = 5000000
  #   Benchmark.bm do |x|
  #     x.report("times:") do
  #       n.times do
  #         ob.add_order create_order(1, 100, 1.1, 30500)
  #         ob.add_order create_order(2, 104, 1.10, 30600, bid_side)
  #       end
  #     end
  #     x.report("upto:") do
  #       1.upto(n) do
  #         ob.add_order create_order(1, 100, 1.1, 30500)
  #         ob.add_order create_order(2, 104, 1.10, 30600, bid_side)
  #       end
  #     end
  #   end
  # end
end
