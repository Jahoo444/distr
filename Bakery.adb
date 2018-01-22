-- Author: Jan Tatarynowicz, 204437

with
	Ada.Text_IO;

use
	Ada.Text_IO;

procedure Bakery is
	
	NUM_THREADS : constant Integer := 100;
	
	Entering : Array( 1..NUM_THREADS ) of Boolean;
	Tickets : Array( 1..NUM_THREADS ) of Integer;
	Short_Time : constant Duration := Duration( 1 );
	Wait_Time : constant Duration := Duration( 3 );
	Times_Running : constant Integer := 3;
	
	procedure Initialize is
	begin
		for i in 1..NUM_THREADS loop
			Entering( i ) := false;
			Tickets( i ) := 0;
		end loop;
	end;
	
	function Max( x, y : Integer ) return Integer is
	begin
		if x > y then
			return x;
		else
			return y;
		end if;
	end;
	
	procedure Lock( pid : Integer ) is
		Ticket : Integer := 0;
	begin
		Entering( pid ) := true;
		for i in 1..NUM_THREADS loop
			Ticket := Max( Ticket, Tickets( i ) );
		end loop;
		Tickets( pid ) := Ticket + 1;
		Entering( pid ) := false;
		
		for i in 1..NUM_THREADS loop
			if i /= pid then
				while Entering( i ) loop
					-- Wait for other customers to retrieve their tickets
					delay Short_Time;
				end loop;
				
				while	Tickets( i ) /= 0
						and	( Tickets( pid ) > Tickets( i )
							or ( Tickets( pid ) = Tickets( i ) and pid > i ) ) loop
					delay Short_Time;
				end loop;
			end if;
		end loop;
		
		-- Critical section
		Put_Line( "[" & Integer'Image( pid ) & " ]" & " in critical section" );
		-- End of critical section
	end;
	
	procedure Unlock( pid : Integer ) is
	begin
		Tickets( pid ) := 0;
	end;
	
	task type Customer is
		entry Initialize( id : Integer );
	end Customer;
	
	task body Customer is
		pid : Integer := 0;
		Running : Integer := 0;
	begin
		accept Initialize( id : Integer ) do
			pid := id;
			Running := Times_Running;
		end Initialize;
		
		while Running > 0 loop
			Put_Line( "[" & Integer'Image( pid ) & " ]" & " requesting access to critical section" );
			Lock( pid );
			Unlock( pid );
			Put_Line( "[" & Integer'Image( pid ) & " ]" & " done" );
			delay Wait_Time;
			Running := Running - 1;
		end loop;
	end Customer;
	
	type Customer_Ptr is access all Customer;
	
	Customers : Array( 1..NUM_THREADS ) of Customer_Ptr;
	
begin
	Initialize;
	
	for i in 1..NUM_THREADS loop
		Customers( i ) := new Customer;
		Customers( i ).Initialize( i );
	end loop;
end;