Vim�UnDo� e���x�ih*����s�l���g��K}%��n�     T      assert %{generation: ^expected_generation, absorption: ^expected_absorption} =  M                         \�D�    _�                        	    ����                                                                                                                                                                                                                                                                                                                                                             \�A�    �                 'defmodule Bidding.BiddingBatteryTest do     use Bidding.TestCase         alias Bidding.BiddingBattery     alias Bidding.Commitment   $  alias Bidding.Constraints.Blackout   *  alias Bidding.Constraints.MinimumTimeOff   )  alias Bidding.Constraints.MinimumTimeOn   "  alias Bidding.Costs.RateContract     alias Bidding.Solver.Ask     alias Bidding.Solver.Bid   (  alias EventRouter.Content.BatteryModel       %  describe "max_watts_available/2" do   X    test "for continuous asset, when energy is sufficient, max watts is flex limited" do         model =   1        BiddingBattery.create_continuous_model(%{   )          max_generation_rate_watts: 100,   *          max_absorption_rate_watts: -100,             watt_second_min: 0,   #          watt_second_max: 100_000,   #          watt_second_current: 501,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })             now = VTime.utc_now()             {:ok, result} =   +        BiddingBattery.max_watts_available(             model,             %Ask{                start_datetime: now,               max_seconds: 5,               watts: 100             },             501,             5   	        )             assert result == 100.0       end       m    test "for continuous asset, when energy level is exactly the amount needed, max watts is flex limited" do         model =   1        BiddingBattery.create_continuous_model(%{   )          max_generation_rate_watts: 100,   *          max_absorption_rate_watts: -100,             watt_second_min: 0,   #          watt_second_max: 100_000,   #          watt_second_current: 500,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })             now = VTime.utc_now()             {:ok, result} =   +        BiddingBattery.max_watts_available(             model,             %Ask{                start_datetime: now,               max_seconds: 5,               watts: 100             },             500,             5   	        )             assert result == 100.0       end       \    test "for continuous asset, when energy is insufficient, max watts is energy limited" do         model =   1        BiddingBattery.create_continuous_model(%{   )          max_generation_rate_watts: 100,   *          max_absorption_rate_watts: -100,             watt_second_min: 0,   #          watt_second_max: 100_000,   #          watt_second_current: 200,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })             now = VTime.utc_now()             {:ok, result} =   +        BiddingBattery.max_watts_available(             model,             %Ask{                start_datetime: now,               max_seconds: 5,               watts: 100             },             200,             5   	        )       1      # expect max_watts_available = 200 / 5 = 40         assert result == 40.0       end       h    test "for binary asset, when energy is insufficient, max watts should return 'No Flex available'" do         model =   -        BiddingBattery.create_binary_model(%{   )          max_generation_rate_watts: 100,   *          max_absorption_rate_watts: -100,             watt_second_min: 0,   #          watt_second_max: 100_000,   #          watt_second_current: 200,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })             now = VTime.utc_now()             result =   +        BiddingBattery.max_watts_available(             model,             %Ask{                start_datetime: now,               max_seconds: 5,               watts: 100             },             200,             5   	        )       *      assert result == "No Flex available"       end     end       /  describe "cost_for_storage_state_change/3" do   N    test "returns least storage cost (-101) when storage cost curve is nil" do   .      asset = %BatteryModel{storage_cost: nil}             # least storage cost   \      assert BiddingBattery.cost_for_storage_state_change(asset, 100, 1, :not_used) == -1.01       end       a    test "returns correct cost in the range of [-100, 100] when storage cost curve is defined" do         min_ws = 0         neutral_ws = 50         max_ws = 100             current_ws = 50   J      sc = Bidding.Costs.StorageCost.parabolic(min_ws, neutral_ws, max_ws)   N      asset = %BatteryModel{storage_cost: sc, watt_second_current: current_ws}       7      # cost to generate 50 watts for 1 second duration   Z      assert BiddingBattery.cost_for_storage_state_change(asset, 50, 1, current_ws) == 2.0       7      # cost to generate 25 watts for 1 second duration   Z      assert BiddingBattery.cost_for_storage_state_change(asset, 25, 1, current_ws) == 1.0       end     end         describe "flex_up " do       test "max power" do   O      asset = %BatteryModel{watts_current: 100, max_generation_rate_watts: 100}   /      assert BiddingBattery.flex_up(asset) == 0       end       -    test "has some room to increase power" do   N      asset = %BatteryModel{watts_current: 80, max_generation_rate_watts: 100}   0      assert BiddingBattery.flex_up(asset) == 20       end           test "over the limit" do   O      asset = %BatteryModel{watts_current: 180, max_generation_rate_watts: 100}   /      assert BiddingBattery.flex_up(asset) == 0       end     end         describe "flex_down " do       test "max absorption" do   Q      asset = %BatteryModel{watts_current: -100, max_absorption_rate_watts: -100}   1      assert BiddingBattery.flex_down(asset) == 0       end       0    test "has some room to absorb more power" do   O      asset = %BatteryModel{watts_current: 80, max_absorption_rate_watts: -100}   3      assert BiddingBattery.flex_down(asset) == 180       end       '    test "over the absorption limit" do   Q      asset = %BatteryModel{watts_current: -180, max_absorption_rate_watts: -100}   1      assert BiddingBattery.flex_down(asset) == 0       end     end       0  describe "Creating invalid BiddingBatterys" do   *    test "Max gen must be non-negative" do   R      assert_raise ArgumentError, "Max Generation must be positive or zero", fn ->   1        BiddingBattery.create_continuous_model(%{   )          max_generation_rate_watts: -10,   )          max_absorption_rate_watts: -20,             watt_second_min: 0,             watt_second_max: 100,   "          watt_second_current: 50,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })   	      end       end       1    test "Max absorption must be non-positive" do   R      assert_raise ArgumentError, "Max Absorption must be negative or zero", fn ->   1        BiddingBattery.create_continuous_model(%{   (          max_generation_rate_watts: 10,   '          max_absorption_rate_watts: 3,             watt_second_min: 0,             watt_second_max: 100,   "          watt_second_current: 50,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })   	      end       end     end         describe "Available Flex:" do       setup do         [           model:   3          BiddingBattery.create_continuous_model(%{               id: Factory.id(),   *            max_absorption_rate_watts: -3,   *            max_generation_rate_watts: 10,               storage_cost: nil,   $            watt_second_current: 50,   !            watt_second_max: 100,               watt_second_min: 0,               watts_current: 0             }),           ramp_model:   3          BiddingBattery.create_continuous_model(%{               id: Factory.id(),   +            max_absorption_rate_watts: -10,   *            max_generation_rate_watts: 10,   +            power_flex_down_ramp_rate: -60,   (            power_flex_up_ramp_rate: 60,               storage_cost: nil,   $            watt_second_current: 50,   !            watt_second_max: 100,               watt_second_min: 0,               watts_current: 5             }),           now: VTime.utc_now()         ]       end       /    test "when when no commitments", fixture do   1      assert %{generation: 10, absorption: -3} ==   K               BiddingBattery.available_flex(fixture.model, fixture.now, 5)       end       2    test "when generation bid in play", fixture do         model =   A        BiddingBattery.add_commitment(fixture.model, %Commitment{             watts: 1,             seconds: 5,   !          start_time: fixture.now   
        })       0      assert %{generation: 9, absorption: -4} ==   C               BiddingBattery.available_flex(model, fixture.now, 5)       end       2    test "when absorption bid in play", fixture do         model =   A        BiddingBattery.add_commitment(fixture.model, %Commitment{             watts: -1,             seconds: 5,   !          start_time: fixture.now   
        })       1      assert %{generation: 11, absorption: -2} ==   C               BiddingBattery.available_flex(model, fixture.now, 5)       end       ?    test "when have a ramp rate but no commitments", fixture do   0      assert %{generation: 5, absorption: -5} ==   P               BiddingBattery.available_flex(fixture.ramp_model, fixture.now, 5)       end       P    # We have several different numbers in play, this is how it should shake out       #   9    # 15  <- max_generation_rate_watts (relative, so +10)       # .       # .       # .   $    # .   <- ramp up from commitment   !    # 10  <- ramp up from current       # .       # .       # .   /    # .   <- commitment watts (relative, so +1)       # 5   <- watts_current       # .       # .       # .   &    # .   <- ramp down from commitment   #    # 0   <- ramp down from current       # .       # .       # .       # .   ;    # -5  <- max_absorption_rate_watts (relativate, so -10)   G    test "when have a ramp rate and generation bid in play", fixture do         commitment = %Commitment{           watts: 1,           seconds: 5,           start_time: fixture.now         }       K      model = BiddingBattery.add_commitment(fixture.ramp_model, commitment)   [      ramp_up = round(fixture.ramp_model.power_flex_up_ramp_rate / 60 * commitment.seconds)   _      ramp_down = round(fixture.ramp_model.power_flex_down_ramp_rate / 60 * commitment.seconds)             expected_generation =   U        min(fixture.ramp_model.max_generation_rate_watts - commitment.watts, ramp_up)             expected_absorption =   W        max(fixture.ramp_model.max_absorption_rate_watts - commitment.watts, ramp_down)       T      assert %{generation: ^expected_generation, absorption: ^expected_absorption} =   C               BiddingBattery.available_flex(model, fixture.now, 5)       end       G    test "when have a ramp rate and absorption bid in play", fixture do         commitment = %Commitment{           watts: -1,           seconds: 5,           start_time: fixture.now         }       K      model = BiddingBattery.add_commitment(fixture.ramp_model, commitment)   [      ramp_up = round(fixture.ramp_model.power_flex_up_ramp_rate / 60 * commitment.seconds)   _      ramp_down = round(fixture.ramp_model.power_flex_down_ramp_rate / 60 * commitment.seconds)             expected_generation =   U        min(fixture.ramp_model.max_generation_rate_watts - commitment.watts, ramp_up)             expected_absorption =   W        max(fixture.ramp_model.max_absorption_rate_watts - commitment.watts, ramp_down)       T      assert %{generation: ^expected_generation, absorption: ^expected_absorption} =   C               BiddingBattery.available_flex(model, fixture.now, 5)       end       I    test "when have a ramp rate and ramp can exceed max rate", fixture do         commitment = %Commitment{           watts: 7,           seconds: 5,           start_time: fixture.now         }       K      model = BiddingBattery.add_commitment(fixture.ramp_model, commitment)   [      ramp_up = round(fixture.ramp_model.power_flex_up_ramp_rate / 60 * commitment.seconds)   _      ramp_down = round(fixture.ramp_model.power_flex_down_ramp_rate / 60 * commitment.seconds)             expected_generation =   U        min(fixture.ramp_model.max_generation_rate_watts - commitment.watts, ramp_up)             expected_absorption =   W        max(fixture.ramp_model.max_absorption_rate_watts - commitment.watts, ramp_down)       T      assert %{generation: ^expected_generation, absorption: ^expected_absorption} =   C               BiddingBattery.available_flex(model, fixture.now, 5)       end       [    test "when have a ramp rate and ramp can exceed max rate but overcommitted", fixture do         commitment = %Commitment{           watts: 11,           seconds: 5,           start_time: fixture.now         }       K      model = BiddingBattery.add_commitment(fixture.ramp_model, commitment)   _      ramp_down = round(fixture.ramp_model.power_flex_down_ramp_rate / 60 * commitment.seconds)             expected_absorption =   W        max(fixture.ramp_model.max_absorption_rate_watts - commitment.watts, ramp_down)       A      assert %{generation: 0, absorption: ^expected_absorption} =   C               BiddingBattery.available_flex(model, fixture.now, 5)             commitment = %Commitment{           watts: -11,           seconds: 5,           start_time: fixture.now         }       K      model = BiddingBattery.add_commitment(fixture.ramp_model, commitment)   [      ramp_up = round(fixture.ramp_model.power_flex_up_ramp_rate / 60 * commitment.seconds)             expected_generation =   U        min(fixture.ramp_model.max_generation_rate_watts - commitment.watts, ramp_up)       A      assert %{generation: ^expected_generation, absorption: 0} =   C               BiddingBattery.available_flex(model, fixture.now, 5)       end     end       -  describe "Average generation/absorption" do       setup do         model1 =   1        BiddingBattery.create_continuous_model(%{   (          max_generation_rate_watts: 10,   (          max_absorption_rate_watts: -5,             watt_second_min: 0,             watt_second_max: 100,   "          watt_second_current: 50,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })             model2 =   1        BiddingBattery.create_continuous_model(%{   (          max_generation_rate_watts: 20,   )          max_absorption_rate_watts: -15,             watt_second_min: 0,             watt_second_max: 100,   "          watt_second_current: 50,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })             [           model1: model1,           model2: model2,           model1_key: model1.id,           model2_key: model2.id         ]       end       )    test "gen with one asset", fixture do   ]      assert 10 == BiddingBattery.average_generation(%{fixture.model1_key => fixture.model1})       end       )    test "gen with two asset", fixture do         assert 15 ==   3               BiddingBattery.average_generation(%{   6                 fixture.model1_key => fixture.model1,   5                 fixture.model2_key => fixture.model2                  })       end       ,    test "absorb with one asset", fixture do   ]      assert BiddingBattery.average_absorption(%{fixture.model1_key => fixture.model1}) == -5       end       ,    test "absorb with two asset", fixture do   1      assert BiddingBattery.average_absorption(%{   4               fixture.model1_key => fixture.model1,   3               fixture.model2_key => fixture.model2                }) == -10       end     end         describe "Bidding no cost" do       setup do         model =   1        BiddingBattery.create_continuous_model(%{   (          max_generation_rate_watts: 10,   (          max_absorption_rate_watts: -5,             watt_second_min: 0,              watt_second_max: 1000,   #          watt_second_current: 500,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })             id = model.id         now = VTime.utc_now()             [           model: model,           id: id,           now: now         ]       end       C    test "Ask for less power (5W) than available (10W)", fixture do         watts = 5         min_seconds = 10         max_seconds = 10   A      ask = Ask.new(fixture.now, watts, min_seconds, max_seconds)         id = fixture.id       9      result = BiddingBattery.get_bid(fixture.model, ask)             assert %Bid{                  type: :bid,                  watts: 5,                  min_seconds: 10,   +               watt_seconds_available: 500,                  model_id: ^id                } = result       end       D    test "Ask for more power (15W) than available (10W)", fixture do         watts = 15         min_seconds = 10         max_seconds = 10   A      ask = Ask.new(fixture.now, watts, min_seconds, max_seconds)         id = fixture.id             assert %Bid{                  type: :bid,                  watts: 10,                  min_seconds: 10,   +               watt_seconds_available: 500,                  model_id: ^id   ;             } = BiddingBattery.get_bid(fixture.model, ask)       end       `    test "Ask for more energy (10*200 watt seconds) than storage (500 watt seconds)", fixture do         watts = 10         min_seconds = 200         max_seconds = 200   A      ask = Ask.new(fixture.now, watts, min_seconds, max_seconds)       9      result = BiddingBattery.get_bid(fixture.model, ask)             # 500Ws / 200s = 2.5W   a      assert %Bid{type: :bid, watts: 2.5, min_seconds: 200, watt_seconds_available: 500} = result       end       4    test "Ask when no storage available", fixture do   .      ask = Ask.new(fixture.now, 10, 200, 200)   K      updated_model = BiddingBattery.update_storage_level(fixture.model, 0)       B      assert %Bid{type: :no_bid, reason: "No Storage Available"} =   9               BiddingBattery.get_bid(updated_model, ask)       end     end       *  describe "Bidding with Rate Contract" do       setup do         model =   
        %{   (          max_generation_rate_watts: 10,   (          max_absorption_rate_watts: -5,             watt_second_min: 0,              watt_second_max: 1000,   #          watt_second_current: 500,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   	        }   3        |> BiddingBattery.create_continuous_model()   \        |> BiddingBattery.add_rate_contract(RateContract.create_fixed(%{buy: 10, sell: 20}))             now = VTime.utc_now()             [           model: model,           now: now         ]       end       !    test "Sell power", fixture do   .      ask = Ask.new(fixture.now, 10, 200, 200)       Y      assert %Bid{cents_per_watt_second: 20} = BiddingBattery.get_bid(fixture.model, ask)       end            test "Buy power", fixture do   /      ask = Ask.new(fixture.now, -10, 200, 200)       Y      assert %Bid{cents_per_watt_second: 10} = BiddingBattery.get_bid(fixture.model, ask)       end     end       -  describe "Bidding without Rate Contract" do       setup do         model =   1        BiddingBattery.create_continuous_model(%{   (          max_generation_rate_watts: 10,   (          max_absorption_rate_watts: -5,             watt_second_min: 0,              watt_second_max: 1000,   #          watt_second_current: 500,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })             now = VTime.utc_now()             [           model: model,           now: now         ]       end       !    test "Sell power", fixture do   .      ask = Ask.new(fixture.now, 10, 200, 200)       X      assert %Bid{cents_per_watt_second: 0} = BiddingBattery.get_bid(fixture.model, ask)       end            test "Buy power", fixture do   /      ask = Ask.new(fixture.now, -10, 200, 200)       X      assert %Bid{cents_per_watt_second: 0} = BiddingBattery.get_bid(fixture.model, ask)       end     end       $  describe "Blackout Constraints" do       setup do         model =   1        BiddingBattery.create_continuous_model(%{   (          max_generation_rate_watts: 10,   (          max_absorption_rate_watts: -5,             watt_second_min: 0,              watt_second_max: 1000,   #          watt_second_current: 500,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })       <      {:ok, con} = Blackout.create_daily(10, 0, 0, 11, 0, 0)   @      model = BiddingBattery.add_blackout_constraint(model, con)         now = VTime.utc_now()             [           model: model,           now: now         ]       end       %    test "no-bid overlap", fixture do         {:ok, date_time} =   W        Calendar.DateTime.from_erl({{2014, 9, 26}, {10, 10, 20}}, "America/Montevideo")       ,      ask = Ask.new(date_time, 10, 500, 500)       H      assert %Bid{type: :no_bid, reason: "Violation of Blackout time"} =   9               BiddingBattery.get_bid(fixture.model, ask)       end       %    test "bid no overlap", fixture do         {:ok, date_time} =   V        Calendar.DateTime.from_erl({{2014, 9, 26}, {9, 10, 20}}, "America/Montevideo")       ,      ask = Ask.new(date_time, 10, 500, 500)       J      assert %Bid{type: :bid} = BiddingBattery.get_bid(fixture.model, ask)       end     end       &  describe "Min Time On Constraint" do       setup do         model =   1        BiddingBattery.create_continuous_model(%{   (          max_generation_rate_watts: 10,   (          max_absorption_rate_watts: -5,             watt_second_min: 0,              watt_second_max: 1000,   #          watt_second_current: 500,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })       +      constraint = MinimumTimeOn.create(60)   Q      model = BiddingBattery.update_minimum_time_on_constraint(model, constraint)         now = VTime.utc_now()             [           model: model,           now: now         ]       end       5    test "ask for less than min duration", fixture do   *      ask = Ask.new(fixture.now, 10, 5, 5)       [      assert %Bid{type: :bid, min_seconds: 60} = BiddingBattery.get_bid(fixture.model, ask)       end       5    test "ask for more than min duration", fixture do   .      ask = Ask.new(fixture.now, 10, 120, 120)       [      assert %Bid{type: :bid, min_seconds: 60} = BiddingBattery.get_bid(fixture.model, ask)       end     end       '  describe "Min Time Off Constraint" do       setup do         now = VTime.utc_now()             model =   
        %{   (          max_generation_rate_watts: 10,   (          max_absorption_rate_watts: -5,             watt_second_min: 0,              watt_second_max: 1000,   #          watt_second_current: 500,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   	        }   3        |> BiddingBattery.create_continuous_model()   W        |> BiddingBattery.update_minimum_time_off_constraint(MinimumTimeOff.create(60))   ]        |> BiddingBattery.add_commitment(%Commitment{watts: -1, seconds: 5, start_time: now})             [           model: model,           now: now         ]       end       A    test "ask too close to commitment that is before", fixture do   :      ask = Ask.new(VTime.add!(fixture.now, 64), 10, 5, 5)       V      assert %Bid{type: :no_bid, reason: "Violation of Minimum Time Off Constraint"} =   9               BiddingBattery.get_bid(fixture.model, ask)       end       I    test "ask far enough away from commitment that is before", fixture do   :      ask = Ask.new(VTime.add!(fixture.now, 65), 10, 5, 5)       J      assert %Bid{type: :bid} = BiddingBattery.get_bid(fixture.model, ask)       end       @    test "ask too close to commitment that is after", fixture do   M      ask = Ask.new(Calendar.DateTime.subtract!(fixture.now, 69), 10, 10, 10)       V      assert %Bid{type: :no_bid, reason: "Violation of Minimum Time Off Constraint"} =   9               BiddingBattery.get_bid(fixture.model, ask)       end       H    test "ask far enough away from commitment that is after", fixture do   M      ask = Ask.new(Calendar.DateTime.subtract!(fixture.now, 70), 10, 10, 10)       J      assert %Bid{type: :bid} = BiddingBattery.get_bid(fixture.model, ask)       end     end         describe "Binary Asset" do       setup do         model =   -        BiddingBattery.create_binary_model(%{   (          max_generation_rate_watts: 10,   (          max_absorption_rate_watts: -5,             watt_second_min: 0,   "          watt_second_max: 10_000,   %          watt_second_current: 8_000,             watts_current: 3,             id: Factory.id(),             storage_cost: nil   
        })             [           model: model         ]       end       8    test "ask for less than flex generation", fixture do         {:ok, date_time} =   W        Calendar.DateTime.from_erl({{2014, 9, 26}, {10, 10, 20}}, "America/Montevideo")       +      ask = Ask.new(date_time, 5, 500, 500)       G      assert %Bid{type: :bid, watts: 10, absolute_setpoint_watts: 13} =   9               BiddingBattery.get_bid(fixture.model, ask)       end       8    test "ask for more than flex generation", fixture do         {:ok, date_time} =   W        Calendar.DateTime.from_erl({{2014, 9, 26}, {10, 10, 20}}, "America/Montevideo")       ,      ask = Ask.new(date_time, 15, 500, 500)       G      assert %Bid{type: :bid, watts: 10, absolute_setpoint_watts: 13} =   9               BiddingBattery.get_bid(fixture.model, ask)       end       8    test "ask for less than flex absorption", fixture do         {:ok, date_time} =   W        Calendar.DateTime.from_erl({{2014, 9, 26}, {10, 10, 20}}, "America/Montevideo")       ,      ask = Ask.new(date_time, -2, 500, 500)       G      assert %Bid{type: :bid, watts: -5, absolute_setpoint_watts: -2} =   9               BiddingBattery.get_bid(fixture.model, ask)       end       8    test "ask for more than flex absorption", fixture do         {:ok, date_time} =   W        Calendar.DateTime.from_erl({{2014, 9, 26}, {10, 10, 20}}, "America/Montevideo")       -      ask = Ask.new(date_time, -10, 500, 500)       G      assert %Bid{type: :bid, watts: -5, absolute_setpoint_watts: -2} =   9               BiddingBattery.get_bid(fixture.model, ask)       end     end       3  describe "Binary Absorption Only Currently On" do       setup do         model =   -        BiddingBattery.create_binary_model(%{   (          max_generation_rate_watts: 10,   '          max_absorption_rate_watts: 0,             watt_second_min: 0,              watt_second_max: 1000,   #          watt_second_current: 900,             watts_current: -10,             id: Factory.id(),             storage_cost: nil   
        })             now = VTime.utc_now()             [           model: model,           now: now         ]       end       8    test "ask for less than flex generation", fixture do   -      ask = Ask.new(fixture.now, 5, 500, 500)       F      assert %Bid{type: :bid, watts: 10, absolute_setpoint_watts: 0} =   9               BiddingBattery.get_bid(fixture.model, ask)       end       ;    test "ask for more (-15W) than flex (-10W)", fixture do   /      ask = Ask.new(fixture.now, -15, 500, 500)       L      assert %Bid{type: :no_bid, watts: nil, absolute_setpoint_watts: nil} =   9               BiddingBattery.get_bid(fixture.model, ask)       end       8    test "ask for more than flex absorption", fixture do   .      ask = Ask.new(fixture.now, -1, 500, 500)             assert %Bid{                  type: :no_bid,                  watts: nil,   ,               absolute_setpoint_watts: nil,   *               reason: "No Flex available"   ;             } = BiddingBattery.get_bid(fixture.model, ask)       end     end       H  describe "Binary Absorption Only Currently Off, flex-limited asset" do       setup do         model =   -        BiddingBattery.create_binary_model(%{   '          max_generation_rate_watts: 0,   )          max_absorption_rate_watts: -10,             watt_second_min: 0,   #          watt_second_max: 100_000,   &          watt_second_current: 50_000,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })             now = VTime.utc_now()             [           model: model,           now: now         ]       end       8    test "ask for more than flex generation", fixture do   -      ask = Ask.new(fixture.now, 1, 500, 500)             assert %Bid{                  type: :no_bid,                  watts: nil,   ,               absolute_setpoint_watts: nil,   *               reason: "No Flex available"   ;             } = BiddingBattery.get_bid(fixture.model, ask)       end       8    test "ask for less than flex absorption", fixture do   .      ask = Ask.new(fixture.now, -5, 500, 500)       I      assert %Bid{type: :bid, watts: -10, absolute_setpoint_watts: -10} =   9               BiddingBattery.get_bid(fixture.model, ask)       end       8    test "ask for more than flex absorption", fixture do   /      ask = Ask.new(fixture.now, -15, 500, 500)       9      result = BiddingBattery.get_bid(fixture.model, ask)   P      assert %Bid{type: :bid, watts: -10, absolute_setpoint_watts: -10} = result       end     end       K  describe "Binary Absorption Only Currently Off, energy-limited assets" do       setup do         model1 =   -        BiddingBattery.create_binary_model(%{   '          max_generation_rate_watts: 0,   )          max_absorption_rate_watts: -10,             watt_second_min: 0,             watt_second_max: 100,   "          watt_second_current: 40,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })             model2 =   -        BiddingBattery.create_binary_model(%{   '          max_generation_rate_watts: 0,   )          max_absorption_rate_watts: -10,             watt_second_min: 0,             watt_second_max: 100,   "          watt_second_current: 60,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })             now = VTime.utc_now()             [           model1: model1,           model2: model2,           now: now         ]       end       >    # asset can absorb exactly 5s * 10W = 50Ws of energy in 5s   V    test "ask to absorb less energy than asset is capable of (50Ws) in 5s", fixture do   Y      # Model 1 Energy capacity = watt_second_max - watt_second_current = 100 - 40 = 60Ws   R      # This asset has enough energy to operate at -60Ws/5 = -12W for 5s but it is   <      # flex limited to "max_absorption_rate_watts" of -10W.       *      ask = Ask.new(fixture.now, -8, 5, 5)             assert %Bid{                  type: :bid,                  watts: -10,   +               absolute_setpoint_watts: -10   <             } = BiddingBattery.get_bid(fixture.model1, ask)       end       P    test "ask to absorb more energy than asset is capable of (50Ws)", fixture do   Q      # Energy capacity = watt_second_max - watt_second_current = 100 - 60 = 40Ws   K      # This asset has NOT enough energy to operate at -40Ws/5 = -8W for 5s       -      # ask to absorb 50Ws Ws i.e. 10W for 5s   +      ask = Ask.new(fixture.now, -10, 5, 5)             assert %Bid{                  type: :no_bid,                  watts: nil,   ,               absolute_setpoint_watts: nil,   *               reason: "No Flex available"   <             } = BiddingBattery.get_bid(fixture.model2, ask)       end     end       K  describe "Binary Generation Only Currently Off, energy-limited assets" do       setup do         model1 =   -        BiddingBattery.create_binary_model(%{   (          max_generation_rate_watts: 10,   '          max_absorption_rate_watts: 0,             watt_second_min: 0,             watt_second_max: 100,   "          watt_second_current: 60,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })             model2 =   -        BiddingBattery.create_binary_model(%{   (          max_generation_rate_watts: 10,   '          max_absorption_rate_watts: 0,             watt_second_min: 0,             watt_second_max: 100,   "          watt_second_current: 40,             watts_current: 0,             id: Factory.id(),             storage_cost: nil   
        })             now = VTime.utc_now()             [           model1: model1,           model2: model2,           now: now         ]       end       @    # asset can generate exactly 5s * 10W = 50Ws of energy in 5s   X    test "ask to generate less energy than asset is capable of (50Ws) in 5s", fixture do   <      # Model 1 Energy capacity = watt_second_current = 60Ws   P      # This asset has enough energy to operate at 60Ws/5 = 12W for 5s but it is   ;      # flex limited to "max_generation_rate_watts" of 10W.       )      ask = Ask.new(fixture.now, 8, 5, 5)             assert %Bid{                  type: :bid,                  watts: 10,   *               absolute_setpoint_watts: 10   <             } = BiddingBattery.get_bid(fixture.model1, ask)       end       X    test "ask to generate more energy than asset is capable of (50Ws) in 5s", fixture do   @      # Model 2 has Energy capacity = watt_second_current = 40Ws   7      # This asset has to operate at 40Ws/5 = 8W for 5s       /      # ask to generate 50Ws Ws i.e. 10W for 5s   *      ask = Ask.new(fixture.now, 10, 5, 5)             assert %Bid{                  type: :no_bid,                  watts: nil,   ,               absolute_setpoint_watts: nil,   *               reason: "No Flex available"   <             } = BiddingBattery.get_bid(fixture.model2, ask)       end     end   end5�_�                    M       ����                                                                                                                                                                                                                                                                                                                                                             \�D�    �  L  N        T      refute %{generation: ^expected_generation, absorption: ^expected_absorption} =5��