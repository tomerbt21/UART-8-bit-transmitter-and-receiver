module UART_TX
#(parameter BR = 9600, 
            CLK_RATE = 50e6) //Clock-rate and Boud-rate (frequency of UART) 
(
 input        clk, reset, 
 input [7:0]  TX_data_in, //8 bits of Data input
 input        transmit, //High for activation
 output       TX_active, //High if the transmitter is active
 output       TX_serial_out_bit //The bit thats being transmitted.
 );
 
 reg [15:0] clk_counter      = 0; //Counts clock cycles
 reg [10:0] shift_reg        = 11'b00000000001; //The whole data package for transmission(data,start,stop,parity)
 reg        reg_active       = 0; 
 reg        reg_parity       = 0; //Even parity bit calculated
 reg        state            = 0; //Current state of the transmission process
 
 parameter IDLE              = 1'b0, //The states of our machine
           TRANSMIT          = 1'b1;
 parameter POSEDGES_FOR_BIT  = CLK_RATE/BR; //CLKS_PER_BIT
 integer   i;
 
 assign TX_active         = reg_active; 
 assign TX_serial_out_bit = shift_reg[0]; //First bit of data
 
 always @ (posedge clk or posedge reset)		
  begin
  
    if (reset)
     begin
      clk_counter    <= 0;
      reg_parity     <= 0;
      shift_reg      <= 11'b00000000001; //We want the LSB bit to be '1' for no transmission
      reg_active     <= 0;
      state          <= IDLE;
     end
	
    else
     begin
	     
      case(state)
	  
	    IDLE: 
		 begin
		   clk_counter  <= 0;
	       reg_parity   <= 0;
           shift_reg    <= 11'b00000000001;
           reg_active   <= 0;
		   if (transmit == 1) //Transmitter is ready to send data
		    begin
		     for (i = 0; i < 8; i = i + 1) 
	          reg_parity <= reg_parity ^ TX_data_in[i]; //Calculate the even parity bit
	         shift_reg   <= {1'b1, reg_parity, TX_data_in, 1'b0}; //Start,parity,data,stop
		     state	     <= TRANSMIT;
		     reg_active  <= 1;
	         clk_counter <= 1; //We want to start the transmission now
		    end 
		   else 
		     state <= IDLE;
	        end
		 
           TRANSMIT: 
		    begin
		      if (clk_counter >= POSEDGES_FOR_BIT-1) //We wait for the right rate
		       begin
		        shift_reg <= shift_reg >> 1; //We need the LSB for the serial transmission, right shift
		        if (shift_reg == 0)
			 begin
		          clk_counter <= 0;
			  state       <= IDLE;
		         end 
			 clk_counter <= 0; 
			end   
		     else  
                      clk_counter <= clk_counter + 1; 
                    end
		 
           default: 
		    state = IDLE;
      endcase 
     end
   end
endmodule