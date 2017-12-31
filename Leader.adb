-- Author: Jan Tatarynowicz, 204437

with
	Ada.Text_IO,
	Ada.Numerics.Discrete_Random;

use
	Ada.Text_IO;

procedure Leader is
	
	type Node;
	type Node_Ptr is access all Node;
	
	type Node( V1, V2 : Integer ) is record
		Val1 : Integer := V1;
		Val2 : Integer := V2;
		Next : Node_Ptr := null;
	end record;
	
	type List is record
		Size : Natural := 0;
		First : Node_Ptr := null;
		Last : Node_Ptr := null;
	end record;
	
	type List_Ptr is access all List;
	
	procedure List_Push( L : List_Ptr; V1, V2 : Integer ) is
		New_Node : Node_Ptr;
	begin
		New_Node := new Node( V1, V2 );
		
		if L.Size = 0 then
		begin
			L.First := New_Node;
			L.Last := New_Node;
		end;
		else
		begin
			L.Last.Next := New_Node;
			L.Last := New_Node;
		end;
		end if;
		
		L.Size := L.Size + 1;
	end;
	
	function List_Pop( L : List_Ptr ) return Node_Ptr is
		Ret : Node_Ptr;
	begin
		Ret := null;
		
		if L.Size > 0 then
		begin
			Ret := L.First;
			L.First := L.First.Next;
			L.Size := L.Size - 1;
		end;
		end if;
		
		return Ret;
	end;
	
	function Get_Rand_Int( Low, High : Integer ) return Integer is
		subtype Rand_Range is Integer range Low..High;
		package Rand_Int is new Ada.Numerics.Discrete_Random( Rand_Range );
		Seed : Rand_Int.Generator;
		Num : Integer;
	begin
		Rand_Int.Reset( Seed );
		Num := Rand_Int.Random( Seed );
		
		return Num;
	end Get_Rand_Int;
	
	NUM_STATIONS : constant Integer := 100;
	
	CHANNEL_EMPTY : constant Integer := -1;
	LEADER_CHOSEN : constant Integer := -2;
	ACK : constant Integer := -3;
	ACK_FAILED : constant Integer := -4;
	
	type Station_Status is ( LEADER, NONLEADER, NONE );
	type Channel_Range is range 1..2;
	
	LEFT_IN : constant Channel_Range := 2;
	LEFT_OUT : constant Channel_Range := 1;
	RIGHT_IN : constant Channel_Range := 1;
	RIGHT_OUT : constant Channel_Range := 2;
	
	task type Channel is
		entry Initialize;
		entry Write( Which : Channel_Range; Msg1, Msg2 : Integer );
		entry Read( Which : Channel_Range; Msg1, Msg2 : out Integer );
		entry IsEmpty( Which : Channel_Range; Msg : out Integer );
		entry Done;
	end Channel;
	
	task body Channel is
		Data : array( Channel_Range ) of List_Ptr;
		Accessed : Boolean := false;
		Running : Boolean := true;
		Terminated : Integer := 0;
	begin
		accept Initialize do
			Data( 1 ) := new List;
			Data( 2 ) := new List;

		end Initialize;
		
		while Running loop
			select
				when not Accessed =>
					accept Write( Which : Channel_Range; Msg1, Msg2 : Integer ) do
						Accessed := true;
						List_Push( Data( Which ), Msg1, Msg2 );
						Accessed := false;
					end Write;
			or
				when not Accessed =>
					accept Read( Which : Channel_Range; Msg1, Msg2 : out Integer ) do
						declare
							N : Node_Ptr;
						begin
						Accessed := true;
						N := List_Pop( Data( Which ) );
						
						if N = null then
						begin
							Msg1 := CHANNEL_EMPTY;
							Msg2 := 0;
						end;
						else
						begin
							Msg1 := N.Val1;
							Msg2 := N.Val2;
						end;
						end if;
						Accessed := false;
						end;
					end Read;
			or
				when not Accessed =>
					accept IsEmpty( Which : Channel_Range; Msg : out Integer ) do
					declare
						N : Node_Ptr;
					begin
						Accessed := true;
						N := List_Pop( Data( Which ) );
						
						if N = null then
							Msg := CHANNEL_EMPTY;
						else
							Msg := N.Val1;
						end if;
						Accessed := false;
					end;
					end IsEmpty;
			or
				when not Accessed =>
					accept Done do
						if Terminated = 1 then
							Running := false;
						else
							Terminated := 1;
						end if;
					end Done;
			end select;
		end loop;
	end Channel;
	
	type Channel_Ptr is access Channel;
	
	type Station;
	type Station_Ptr is access all Station;
	
	task type Station is
		entry Initialize( I : Integer; Left : Channel_Ptr; Right : Channel_Ptr );
		entry Start;
	end Station;
	
	task body Station is
		Id : Integer;
		Status : Station_Status := NONLEADER;
		Left_Channel, Right_Channel : Channel_Ptr;
		Running, Phase_Running : Boolean := false;
		Msg1, Msg2, Msg3, Msg4 : Integer;
		Phase, Acks : Integer;
		
		procedure Left_Write( Msg1, Msg2 : Integer ) is
		begin
			Left_Channel.Write( LEFT_OUT, Msg1, Msg2 );
		end Left_Write;
		
		procedure Right_Write( Msg1, Msg2 : Integer ) is
		begin
			Right_Channel.Write( RIGHT_OUT, Msg1, Msg2 );
		end Right_Write;
	begin
		
		accept Initialize( I : Integer; Left : Channel_Ptr; Right : Channel_Ptr ) do
			Id := I;
			Left_Channel := Left;
			Right_Channel := Right;
		end Initialize;
		
		accept Start do
			Running := true;
			Status := NONE;
		end Start;
		
		Phase := 0;
		Acks := 0;
		Msg1 := CHANNEL_EMPTY;
		Msg2 := 0;
		Msg3 := CHANNEL_EMPTY;
		Msg4 := 0;
		
		while Running loop
				
			Msg1 := Id;
			Msg2 := 2 ** Phase;
			
			Left_Write( Msg1, Msg2 );
			Right_Write( Msg1, Msg2 );
			
			Phase_Running := true;
			Acks := 0;
			
			while Phase_Running loop
				Left_Channel.Read( LEFT_IN, Msg1, Msg2 );
				Right_Channel.Read( RIGHT_IN, Msg3, Msg4 );
				
				case Msg1 is
					when LEADER_CHOSEN =>
						begin
							Phase_Running := false;
							Running := false;
							if Msg2 /= Id then
								Right_Write( Msg1, Msg2 );
							end if;
						end;
					
					when ACK =>
						begin
							if Msg2 = Id and Status = NONE then
								Acks := Acks + 1;
							else
								Right_Write( Msg1, Msg2 );
							end if;
						end;
					
					when ACK_FAILED =>
						begin
							if Msg2 = Id and Status = NONE then
								Acks := 0;
								Status := NONLEADER;
							else
								Right_Write( Msg1, Msg2 );
							end if;
						end;
					
					when CHANNEL_EMPTY =>
						null; -- do nothing
					
					when others => -- got id
						begin
							if Msg1 = Id then
							begin
								Status := LEADER;
								Right_Write( LEADER_CHOSEN, Id );
								Running := false;
								Phase_Running := false;
							end;
							elsif Msg1 > Id or Status = NONLEADER then
							begin
								if Msg2 > 1 then
									Right_Write( Msg1, Msg2 - 1 );
								else
									Left_Write( ACK, Msg1 );
								end if;
							end;
							else
								Left_Write( ACK_FAILED, Msg1 );
							end if;
						end;
				end case;
				
				case Msg3 is
					when LEADER_CHOSEN =>
						begin
							Phase_Running := false;
							Running := false;
							if Msg4 /= Id then
								Left_Write( Msg3, Msg4 );
							end if;
						end;
					
					when ACK =>
						begin
							if Msg4 = Id and Status = NONE then
								Acks := Acks + 1;
							else
								Left_Write( Msg3, Msg4 );
							end if;
						end;
					
					when ACK_FAILED =>
						begin
							if Msg4 = Id and Status = NONE then
								Acks := 0;
								Status := NONLEADER;
							else
								Left_Write( Msg3, Msg4 );
							end if;
						end;
					
					when CHANNEL_EMPTY =>
							null; -- do nothing
					
					when others =>
						begin
							if Msg3 = Id then
							begin
								Status := LEADER;
								Left_Write( LEADER_CHOSEN, Id );
								Running := false;
								Phase_Running := false;
							end;
							elsif Msg3 > Id or Status = NONLEADER then
							begin
								if Msg4 > 1 then
									Left_Write( Msg3, Msg4 - 1 );
								else
									Right_Write( ACK, Msg3 );
								end if;
							end;
							else
								Right_Write( ACK_FAILED, Msg3 );
							end if;
						end;
				end case;
				
				if Acks = 2 then
					Phase_Running := false;
				end if;
			end loop;
			
			Phase := Phase + 1;
		end loop;
		
		Left_Channel.Done;
		Right_Channel.Done;
		 
		if Status = LEADER then
			Put_Line( Integer'Image( Id ) & ": I am the leader! (chosen during phase " & Integer'Image( Phase ) & ")" );
		end if;
	end Station;
	
	Ids : array( 1..Num_Stations ) of Integer;
	Stations : array( 1..Num_Stations ) of Station_Ptr;
	Channels : array( 1..Num_Stations ) of Channel_Ptr;

begin
	
	for i in 1..Num_Stations loop
		Ids( i ) := i;
	end loop;
	
	-- Knuth's shuffle
	for i in 1..Num_Stations - 1 loop
	declare
		j, tmp : Integer;
	begin
		j := Get_Rand_Int( 1, Num_Stations - i );
		tmp := Ids( i );
		Ids( i ) := Ids( i + j );
		Ids( i + j ) := tmp;
	end;
	end loop;
	
	for i in 1..Num_Stations loop
		Channels( i ) := new Channel;
		Channels( i ).Initialize;
	end loop;
	
	for i in 1..Num_Stations loop
		Stations( i ) := new Station;
	end loop;
	
	for i in 1..Num_Stations - 1 loop
		Stations( i ).Initialize( Ids( i ), Channels( i ), Channels( i + 1 ) );
	end loop;
	
	Stations( Num_Stations ).Initialize( Ids( Num_Stations ), Channels( Num_Stations ), Channels( 1 ) );
	
	for i in 1..Num_Stations loop
		Stations( i ).Start;
	end loop;
	
	Put_Line( "All started!" );
	
end Leader;