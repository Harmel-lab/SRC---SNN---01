-----------------------------------------------------------------------------
--
-- File : OneSrc_pkg.vhd
--
-- Description : VHDL source code for PLD or FPGA - spike generator - Library
--
-- Chip : Unknow - devel.
--
-- Creation Date : October 14th, 2024
--
-- Last Modification Date : may first, 2025
--
-- Last Modified by : Pascal Harmeling
--									   
-- WARNING : None

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package Src2F_Cbit_pkg is
	component OneSrc
		port (
		    rst             : in std_logic;			                            -- Input        - Reset value
		    clk             : in std_logic;			                            -- Input Clock  - evite le phénomène de course poursuite 
			CurrentInt     	: in std_logic;  					
        
            -- variables spécifiques --
            outSp           : out std_logic			                            -- out spike
 			);
	end component;
end Src2F_Cbit_pkg;

------------------------------------------------------------------
-- Definition des interconnexions -> SPIKING              		--
------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity OneSrc is
	port (
		    rst             : in std_logic;			                            -- Input        - Reset value
		    clk             : in std_logic;			                            -- Input Clock  - evite le phénomène de course poursuite 
			CurrentInt     	: in std_logic;  					
        
            -- variables spécifiques --
            outSp           : out std_logic			                            -- out spike
    );
end entity;

------------------------------------------------------------------
-- Definition de l'architecture neurone -> SPIKING              --
------------------------------------------------------------------
architecture OneSrc_all of OneSrc is 
	--------------------------------------------------------------
	-- Déclaration des variables et signaux internes processus --
	--------------------------------------------------------------
	-- Constants
	constant Zmin		: unsigned(9 downto 0)	:= "0001100100"; --"0001100100"; 		-- !! valeur de Zmin - 100 par d�faut - 	!!
	constant Zmax		: unsigned(9 downto 0)	:= "1110000100"; --"1110000100"; 		-- !! valeur de Zmin - 900 par d�faut - 	!!
																			    
	-------------------------------------------------------------
	-- Déclaration des Fonctions system                        --
	-------------------------------------------------------------  

	begin 
		-------------------------------------------------------------------------------------------------------------
		-- Processus BRC ET OutPut BRC
		-------------------------------------------------------------------------------------------------------------
 		CycleSRC: process (clk,CurrentInt)
        	
		variable tmpFht	    : signed(21 downto 0)	:= to_signed(-1024, 22);	 -- variable de calcul - FHT - valeur réel de -64738 à +64737
		variable tmpFhst	: signed(21 downto 0)	:= to_signed(-800, 22);	     -- variable de calcul - valeur réel de -2097152 to +2097151
		variable tmpFz		: unsigned(9 downto 0)  := Zmax;	                 -- variable de calcul - Fz temp réel
        
        begin 	  
        if rising_edge(clk) then
            if (rst='1') then
                -- initialisation condition t0 equation SRC
                tmpFht := to_signed(-1024, 22);
                tmpFhst := to_signed(-800, 22);
                tmpFz := Zmax;
          
            else
                -- faire calcul de Zreel
                if (tmpFht<500) then tmpFz := Zmax ;
                else tmpFz := Zmin;
                end if;
    
                -- calcul Fht T1 - base CurrentInt
                -- tmpFht := resize(signed(CurrentVec),tmpFht'length) +  shift_left(signed(resize(Fht,tmpFht'length)- shift_left(resize(Fhst,tmpFht'length),2) - 3000),1);
                tmpFht := shift_left(tmpFht - shift_left(tmpFht,2),1);
                if (CurrentInt='1') then
                    tmpFht := tmpFht  - 4976;
                else
                    tmpFht := tmpFht  - 7024;
                end if;
                tmpFht := shift_right((shift_left(tmpFht,1) + tmpFht),2);
    
                -- calcul Fhst T1 -
                tmpFhst := tmpFhst - tmpFhst ;
                tmpFhst := shift_right(resize((tmpFhst * signed(resize(tmpFz,tmpFhst'length))),tmpFhst'length),10) + tmpFhst;		
    
                -- mise à jour des variable principales
                if (tmpFht > 1023 ) then tmpFht := to_signed(1023, tmpFht'length);
                elsif (tmpFht < -1024) then tmpFht := to_signed(-1024, tmpFht'length);
                end if;
         
                if (tmpFhst >1023) then tmpFhst := to_signed(1023, tmpFhst'length);
                elsif (tmpFhst< -800) then tmpFhst := to_signed(-1024, tmpFhst'length);
                end if;    
    
                outSp <= tmpFht(9) and not(tmpFht(21));
            end if;
        end if; 
    end process;			
end OneSrc_all;	  