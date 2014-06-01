defmodule Mqttex.Encoder do
	
	use Bitwise


	def encode(%Mqttex.Msg.Simple{msg_type: type}) when type in [:ping_req, :ping_resp, :disconnect],
		do: <<msg_type_to_binary(type) :: size(4), 0 :: size(4), 0x00>>
	def encode(%Mqttex.Msg.Simple{msg_type: type, msg_id: msg_id}) 
		when type in [:pub_ack, :pub_rec, :pub_comp, :unsub_ack], 
		do: <<msg_type_to_binary(type) :: size(4), 0 :: size(4), 0x02, msg_id :: size(16)>>
	
	def encode(any) do
		IO.inspect any	
	end
	


	#######################################
	###
	### PUB_REL can be duped, so it is not a SImpleMessage!
	###
	#######################################


	@doc "Returns the one byte fixed header and the length encoding"
	def encode_header(%Mqttex.Msg.FixedHeader{message_type: type, duplicate: dup, 
			retain: retain, qos: qos, length: length}) do
		<<msg_type_to_binary(type) :: size(4),
			boolean_to_binary(dup) :: bits, 
			qos_binary(qos) :: size(2), 
			boolean_to_binary(retain) :: bits, 
			encode_length(length) :: binary>>
	end
	
	
	def encode_length(0), do: <<0x00>>
	def encode_length(l) when l <= 268_435_455, do: encode_length(l, <<>>)
	defp encode_length(0, acc), do: acc
	defp encode_length(l, acc) do
		digit = l &&& 0x7f # mod 128
		new_l = l >>> 7 # div 128
		if new_l > 0 do
			# add high bit since there is more to come
			encode_length(new_l, acc <> <<digit ||| 0x80>>)
		else 
			encode_length(new_l, acc <> <<digit>>)
		end
	end
	

	@doc "converts boolean to bits"
	def boolean_to_binary(true), do: <<1 :: size(1)>>
	def boolean_to_binary(false), do: <<0 :: size(1)>>

	@doc "converts atoms the binary qos"
	def qos_binary(:fire_and_forget), do: 0
	def qos_binary(:at_least_once),   do: 1
	def qos_binary(:exactly_once),    do: 2
	def qos_binary(:reserved),        do: 3

	@doc "Converts the atoms to binary message types"
	def msg_type_to_binary(:connect),     do: 1
	def msg_type_to_binary(:conn_ack),    do: 2
	def msg_type_to_binary(:publish),     do: 3
	def msg_type_to_binary(:pub_ack),     do: 4
	def msg_type_to_binary(:pub_rec),     do: 5
	def msg_type_to_binary(:pub_rel),     do: 6
	def msg_type_to_binary(:pub_comp),    do: 7
	def msg_type_to_binary(:subscribe),   do: 8
	def msg_type_to_binary(:sub_ack),     do: 9
	def msg_type_to_binary(:unsubscribe), do: 10
	def msg_type_to_binary(:unsub_ack),   do: 11
	def msg_type_to_binary(:ping_req),    do: 12
	def msg_type_to_binary(:ping_resp),   do: 13
	def msg_type_to_binary(:disconnect),  do: 14
	def msg_type_to_binary(:reserved),    do: 0


end