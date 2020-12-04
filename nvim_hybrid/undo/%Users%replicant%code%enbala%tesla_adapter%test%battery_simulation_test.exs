Vim�UnDo� ��ufl9�t��QjZ��;���F\�MB����H"�   )     alias TeslaAdapter.AssetStore                             \�,�    _�                            ����                                                                                                                                                                                                                                                                                                                                                             \�,�     �          )      (defmodule TeslaAdapter.AssetStoreTest do5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             \�,�    �      '   )   #     alias TeslaAdapter.AssetStore       ,  describe "record and get power reading" do   2    test "retrieves latest power reading value" do         remote_id = UUID.uuid4()   ?      AssetStore.record_reading(remote_id, :power, {:watts, 8})   ?      AssetStore.record_reading(remote_id, :power, {:watts, 5})   8      result = AssetStore.get_reading(remote_id, :power)   "      assert result == {:watts, 5}       end     end       -  describe "record and get energy reading" do   3    test "retrieves latest energy reading value" do         remote_id = UUID.uuid4()   F      AssetStore.record_reading(remote_id, :energy, {:watt_hours, 15})   F      AssetStore.record_reading(remote_id, :energy, {:watt_hours, 10})   9      result = AssetStore.get_reading(remote_id, :energy)   (      assert result == {:watt_hours, 10}       end     end       ,  describe "save and get control message" do   .    test "retrieves latest control message" do         remote_id = UUID.uuid4()             control_message = %{            duration: {:seconds, 3},           power: {:watts, 8},   '        starting_at: DateTime.utc_now()         }       =      assert nil == AssetStore.get_control_message(remote_id)   A      AssetStore.save_control_message(remote_id, control_message)   I      assert control_message == AssetStore.get_control_message(remote_id)5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             \�,�     �         )      &  alias TeslaAdapter.BatterySimulation5��