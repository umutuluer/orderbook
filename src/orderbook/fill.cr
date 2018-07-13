class Fill
  property bid_order : Order,
    ask_order : Order,
    price : Float64,
    amount : Float64,
    maker : Bool,
    fee : Float64,
    side_fee : Float64,
    taker : Bool

  def initialize(@bid_order, @ask_order, @price, @amount, @taker)
    @fee = 0_f64
    @side_fee = 0_f64
    @maker = false
  end

  MAKER_COM_FEE = 0.001
  TAKER_COM_FEE = 0.002

  def write
    @fee = @amount * MAKER_COM_FEE
    @side_fee = @amount * MAKER_COM_FEE

    if @taker
      @fee = @amount * TAKER_COM_FEE
      @side_fee = @amount * TAKER_COM_FEE
    end

    puts "Price : #{@price}, Amount: #{@amount} (Satıcı : #{@bid_order.user_id}, Alıcı: #{@ask_order.user_id}), Fee : #{@fee} Side Fee : #{@side_fee}, Bid : #{@bid_order.id}, Ask: #{@ask_order.id}, Taker: #{@taker}"
  end
end
