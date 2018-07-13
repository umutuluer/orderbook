struct Order
  property! id : Int64,
    user_id : Int32,
    base : String,
    second : String,
    time : Time,
    order_type : String,
    side : String,
    stop : Float64,
    price : Float64,
    samount : Float64,
    easy : Bool,
    amount : Float64

  property status : Int32

  def initialize
    @time = Time.now
    @status = 0
  end
end
