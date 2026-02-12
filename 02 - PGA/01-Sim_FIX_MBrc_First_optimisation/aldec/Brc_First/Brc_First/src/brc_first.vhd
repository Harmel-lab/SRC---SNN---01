-----------------------------------------------------------------------------
--
-- File : SRC_First.vhd
--
-- Description : VHDL source code for PLD or FPGA - spike generator
--
-- Chip : Unknow - devel.
--
-- Creation Date : february 06th, 2024
--
-- Last Modification Date : December 23th, 2024
--
-- Last Modified by : Pascal Harmeling
--
-- Update : optimization 1 - working on rising and falling edges
-- Update : optimization 2 - Initial value Fhst = -350 -> ready to set a spike	  
-- Update : optimization 3 - 	   
-- FIX BUG               4 - Fix bug to Fhst and size of all variables. (23dec2024)
-- WARNING : None
-----------------------------------------------------------------------------
--
-- FUNCTIONAL DESCRIPTION
-- 
--  
-- Requirements: input current 
--
-- Recent Updates
--
--     - Preparation for creating a library for an SRC matrix or SRC vector.
--     - Code optimization.
-----------------------------------------------------------------------------
------------------------------------pascal.harmeling@uliege.be---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Brc_First is 
	port (
   
	-- 3V3 Level I/O
	
 	CLK_1MHZ 	: IN std_logic; 											-- Master clock @ 1 MHz

	Current_Vec : INOUT std_logic_vector(10 downto 0) := "10000011000";		-- Current input [-1000 ... +1000]

	Spike_O 	: OUT std_logic  											-- Output spike pulse
	);

end entity Brc_first;

architecture arch_BRC of Brc_First is	 
	-- pour la simulation --- a détruire
	signal Current_count: signed(15 downto 0)	:= (others => '0');

	-- Variables environnement - Cycle Clock vector
	signal Cycle_clk	: unsigned (1 downto 0)	:= (others => '0');		-- 4 clock cycles 00-01-10-11 -> the 11 cycle is removed

	-- Constants
	constant Zmin   	: unsigned(9 downto 0)	:= "0001100100"; 		-- !! Zmax value during simulation 	!!
	             														-- !! during training 				!!
																		-- !! flux current for bursting 		!!
	signal Zmax_Vec	    : integer range 0 to +1023 := 902;              -- Zmax input where X[0..73]-- base + Zmax_vec -> from 950 to 1023

    signal CurrentInt   : integer range -1024 to +1023 := -1024;        -- Current input INT [-1024 ... +1023]
 
	-- Environment variables - BRC management
	signal Fht			: signed(10 downto 0)	:= (others => '0');		-- H variable 	- real value from -1024 to +1023	 
	signal Fhst			: signed(10 downto 0)	:= (others => '0');		-- Hs variable 	- real value from -1024 to +1023
	signal Fzs			: signed(10 downto 0)	:= (others => '0');		-- zmax variable - real value from -1024 to +1023
	
	-- Environment variables - Startup - reset
	signal CountStart 	: bit := '0' ;									-- startup with initialization

	begin
		CycleBRC: process (CLK_1MHZ)

		variable tmpFht	    : signed(16 downto 0)	:= (others => '0');	-- computation variable - FHT - real value from -64738 to +64737
		variable tmpFhst	: signed(21 downto 0)	:= (others => '0');	-- computation variable - real value from -2097152 to +2097151
		variable tmpFz		: unsigned(9 downto 0)  := (others => '0');	-- computation variable - temporary Fz real?
  	
		begin 								  
			-- update on rising and falling edges - with INIT if CountStart=0 -------
			if	(CLK_1MHZ'event and CLK_1MHZ='1') then
				-- start RESET	   --
				if CountStart ='0' then
					Cycle_clk <= "00";
					Fht <= "00000000000";							  	-- initialize : 0 
					Fhst <= "00000000000";	 							-- "
					Fzs <= "00000000000";								-- "
    	            tmpFht := "00000000000000000";
 	                tmpFhst := "0000000000000000000000";
        	        tmpFz := "0000000000"; 
 					CountStart <= '1';
				    CurrentInt<=  -1024;	 
				
			    -- Start simulation --
				else
					-- generation of 3 machine cycles --
					if (Cycle_clk ="10") then Cycle_clk <= "00";
					else Cycle_clk <= Cycle_clk + 1;
					end if;
					
					Current_count <= Current_count + 1;
					
					-- Implementation of the BRC function -- per cycle
                    -- compute Zreal
                    if (Fht<500) then tmpFz := to_unsigned(Zmax_Vec, tmpFz'length) ;
                    else tmpFz := Zmin;
                    end if;
    
                    -- compute Fht T1 - based on CurrentInt
                    -- tmpFht := resize(signed(CurrentVec),tmpFht'length) +  shift_left(signed(resize(Fht,tmpFht'length)- shift_left(resize(Fhst,tmpFht'length),2) - 3000),1);
					tmpFht := CurrentInt +  shift_left(( resize(Fht,tmpFht'length) - shift_left(resize(Fhst,tmpFht'length),2) - 3000),1);
                    tmpFht := shift_right((shift_left(tmpFht,1) + tmpFht),2);
    
                    -- compute Fhst T1 -
                    tmpFhst := resize(Fhst,tmpFhst'length) - resize(Fht,tmpFhst'length) ;
                    tmpFhst := shift_right(resize((tmpFhst * signed(resize(tmpFz,tmpFhst'length))),tmpFhst'length),10) + resize(Fht,tmpFhst'length) ;		
							
					
					-- Current vector simulation --
					if (Current_count>100) then
						if (Current_count<400) then 
							Current_Vec <= "01111101000";
							CurrentInt<= +1023;
						else 
							Current_Vec <= "10000011000"; --"1111110000011000";
				            CurrentInt<= -1024;
						end if;
					else 
						Current_Vec <= "10000011000";--"1111110000011000";
			            CurrentInt<= -1024;
					end if;

					
				end if;
		end if;  
			 
        if (tmpFht > 1023 ) then Fht <= "01111111111";
        elsif (tmpFht < -1024) then Fht <= "10000000000";
        else Fht <= tmpFht(10 downto 0);
        end if;
 
        if (tmpFhst >1023) then Fhst <= "01111111111";
        elsif (tmpFhst< -800) then Fhst <= "10011100000";
        else Fhst <= tmpFhst(10 downto 0);
        end if;
		
		if 	(Fht(10)='0' and Fht(9)='1') then Spike_O <='1';
		else Spike_O <='0';
		end if;
		
		end process;		
end architecture;
