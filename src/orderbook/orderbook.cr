require "./order"
require "./fill"

class OrderBook
  property bids = [] of Order,
    asks = [] of Order,
    stops = [] of Order,
    fills = [] of Fill

  COMPLETE = 1

  # String consts
  MARKET = "market"
  LIMIT  = "limit"
  ASK    = "ask"
  BID    = "bid"

  def add_order(order : Order)
    order.samount = order.price * order.amount

    if order.side == BID
      bid_add(order)
    elsif order.side == ASK
      ask_add(order)
    end

    fire()
  end

  def ask_add(order : Order)
    @asks << order
    @asks = @asks.sort_by { |order| order.price }
    execute(order)
  end

  def bid_add(order : Order)
    @bids << order
    @bids = @bids.sort_by { |order| order.price }
    execute(order)
  end

  def add_stop(order : Order)
    @stops << order
  end

  def add_fill(bid, ask : Order, price, amount : Float64, taker : Bool)
    @fills << Fill.new(bid, ask, price, amount, taker)
  end

  def execute_market_ask(order : Order, order_index : Int32)
    if order.easy
      @bids.each_with_index do |bid, i|
        if order.amount >= bid.samount
          order.amount -= bid.samount
          @asks[order_index].amount = order.amount
          @bids[i].amount = 0
          @bids[i].status = COMPLETE
          add_fill(bid, order, bid.price, bid.amount, true)
        elsif order.amount < bid.samount
          @bids[i].amount -= (order.amount / bid.price)
          add_fill(bid, order, bid.price, (order.amount / bid.price), true)
          order.amount = 0
          @asks[order_index].amount = order.amount
        end

        if order.amount == 0
          order.status = COMPLETE
          @asks[order_index].status = order.status
          break
        end
      end
    else
      @bids.each_with_index do |bid, i|
        if order.amount >= bid.amount
          order.amount -= bid.amount
          @asks[order_index].amount = order.amount
          @bids[i].amount = 0
          @bids[i].status = COMPLETE
          add_fill(bid, order, bid.price, bid.amount, true)
        elsif order.amount < bid.amount
          @bids[i].amount -= order.amount
          add_fill(bid, order, bid.price, order.amount, true)
          order.amount = 0
          @asks[order_index].amount = order.amount
        end

        if order.amount == 0
          order.status = COMPLETE
          @asks[order_index].status = order.status
          break
        end
      end
    end
  end

  def execute_market_bid(order : Order, order_index : Int32)
    puts "Sell amount #{order.amount}"
    @asks.each_with_index do |ask, i|
      if order.amount > ask.amount
        order.amount -= ask.amount
        @bids[order_index].amount = order.amount
        @asks[i].amount = 0
        @asks[i].status = COMPLETE

        taker = (order.price <= ask.price)
        add_fill(order, ask, ask.price, ask.amount, taker)
      elsif order.amount < ask.amount
        @asks[i].amount -= order.amount
        taker = (order.price <= ask.price)
        add_fill(order, ask, ask.price, order.amount, taker)
        order.amount = 0
        @bids[order_index].amount = order.amount
      end

      if order.amount == 0
        order.status = COMPLETE
        @bids[order_index].status = order.status
        break
      end
    end
  end

  def execute_limit_ask(order : Order, order_index : Int32)
    @bids.each_with_index do |bid, i|
      next if bid.price > order.price

      if order.amount >= bid.amount
        order.amount -= bid.amount
        @asks[order_index].amount = order.amount
        @bids[i].amount = 0
        @bids[i].status = COMPLETE
        taker = (order.price <= bid.price)
        add_fill(bid, order, bid.price, bid.amount, taker)
      elsif order.amount < bid.amount
        @bids[i].amount -= order.amount
        taker = (order.price <= bid.price)
        add_fill(bid, order, bid.price, order.amount, taker)
        order.amount = 0
        @asks[order_index].amount = order.amount
      end

      if order.amount == 0
        order.status = COMPLETE
        @asks[order_index].status = order.status
        break
      end
    end
  end

  def execute_limit_bid(order : Order, order_index : Int32)
    @asks.each_with_index do |ask, i|
      next if ask.price < order.price

      if order.amount >= ask.price
        order.amount -= ask.amount
        @bids[order_index].amount = order.amount
        @asks[i].amount = 0
        @asks[i].status = COMPLETE
        add_fill(order, ask, ask.price, ask.amount, false)
      elsif order.amount < ask.amount
        @asks[i].amount -= order.amount
        add_fill(order, ask, ask.price, order.amount, true)
        order.amount = 0
        @bids[order_index].amount = order.amount
      end

      if order.amount == 0
        order.status = COMPLETE
        @bids[order_index].status = order.status
        break
      end
    end
  end

  def execute(order : Order)
    order_index = get_index(order)

    if order.order_type == MARKET
      if order.side == ASK
        execute_market_ask(order, order_index)
      elsif order.side == BID
        execute_market_bid(order, order_index)
      end
    end

    if order.order_type == LIMIT
      if order.side == ASK
        execute_limit_ask(order, order_index)
      elsif order.side == BID
        execute_limit_bid(order, order_index)
      end
    end

    clean_complete()
  end

  def fire
    best_ask = 0_f64
    best_bid = 0_f64

    if @asks.size > 0
      best_ask = @asks[0].price
    end

    if @bids.size > 0
      best_bid = @bids[0].price
    end

    @stops.each_with_index do |stop_item, i|
      if stop_item.side == ASK
        if stop_item.stop >= best_ask
          ask_add(stop_item)
          stop_item.status = COMPLETE
          puts "Triggered : #{stop_item.id}"
        end
      elsif stop_item.side == BID
        if stop_item.stop <= best_bid
          bid_add(stop_item)
          stop_item.status = COMPLETE
          puts "Triggered : #{stop_item.id}"
        end
      end
    end
  end

  def clean_complete
    [@bids, @asks, @stops].each do |item|
      remove_complete_orders item
    end
  end

  def remove_complete_orders(order_list : Array)
    loop do
      i = order_list.bsearch_index { |order, i| order.status == COMPLETE }
      break if i.nil?
      order_list.delete_at(i)
    end
  end

  def get_index(order : Order)
    orders = order.side == ASK ? @asks : @bids
    index = orders.index(order)

    index.nil? ? -1 : index
  end
end
