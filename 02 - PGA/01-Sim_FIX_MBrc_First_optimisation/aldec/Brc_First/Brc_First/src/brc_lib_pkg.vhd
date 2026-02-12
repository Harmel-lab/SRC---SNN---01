-----------------------------------------------------------------------------
--
-- File : brc_lib_pkg.vhd
--
-- Description : VHDL source code for PLD or FPGA - spike generator - Library
--
-- Chip : Unknow - devel.
--
-- Creation Date : October 14th, 2024
--
-- Last Modification Date : January 2th, 2025
--
-- Last Modified by : Pascal Harmeling
--									   
--
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
--     	- Préparation création librairie pour BRC matrix ou BRC vector.
--     	- Optimisation du code.
--	   	- Suppression des cycles d'horloge -> ajout Variables
--     	- Suppression du processe de gestion output et DAC
--	   	- Suppression de la constante Zmax_max
-- December 29th 2024
--		- Fix Bugs and reduce size of all buffers to well manage memories
-- January 2th 2025
--		- bursting code - first test
----------------------------------------------------------------------------- 
-- remarques:
--       - a vérifier : Fzt n'est pas un registre utile -> à effecer?
------------------------------------pascal.harmeling@uliege.be---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity brc_lib_pkg is
	port (
 	CLK_1MHZ 	: IN std_logic; 							-- Master clock @ 1 MHz

	Current_Vec 	: IN std_logic_vector(10 downto 0);			-- Current input [-1000 ... +1000]
	Zmax_Vec		: IN signed(10 downto 0);					-- Zmax input where X[0..73]-- base + Zmax_vec -> from 950 to 1023
														-- !! durant un apprentissage 				!!
														-- !! courant de flux pour bursting 		!!
														-- !!  01110000100 = 900		*			!!
														-- !!  01110110110 = 950					!!
 														-- !!  01111010100 = 980					!!
														-- !!  01111101000 = 1000					!!
														-- !!  01111110010 = 1010					!! 
														-- !!  01111111100 = 1020					!!
	
	BRset 		: IN std_logic; 							-- Bursting set mode
	BRZ_Vec		: IN signed(10 downto 0);					-- BRZ input bursting set value - LOW
	BRmin		: IN signed(7 downto 0);					-- BRZ input counter - low value - start 
	BRmax		: IN signed(7 downto 0);					-- BRZ input counter - high value - stop 
	BRzv			: INOUT signed(20	 downto 0);				-- Ouput counter bursting vector
	
	Spike_O 		: INOUT std_logic;						-- Output spike pulse
	Spike_Vec	: INOUT std_logic_vector(10 downto 0)		-- Ouput spike to DAC	
	);

end entity;

------------------------------------------------------------------
-- Définition de l'architecture neurone -> SPIKING              --
------------------------------------------------------------------
architecture S_BRC of brc_lib_pkg is 
	--------------------------------------------------------------
	-- DÃ©claration des variables et signaux internes processus --
	--------------------------------------------------------------
	-- Constants
	constant Zmin			: signed(10 downto 0)	:= "00001100100"; 		-- !! valeur de Zmin - 100 par défaut - 	!!
																	-- !! durant un apprentissage 				!!
	-- Variables environnement - Gestion du BRC
	signal Fht			: signed(10 downto 0)	:= (others => '0');		-- variable H 	- valeur rÃ©el de -1024 Ã  + 1023	 
	signal Fhst			: signed(10 downto 0)	:= (others => '0');		-- variable Hs 	- valeur rÃ©el de -1024 Ã  + 1023
	signal Fzs			: signed(10 downto 0)	:= (others => '0');		-- variable zmax- valeur rÃ©el de -1024 Ã  + 1023
	
	-- Variables environnement - DÃ©marrage - reset 
	signal CountStart 	: bit := '0' ;								-- dÃ©marrage avec initialisation
	
	begin 
		-------------------------------------------------------------------------------------------------------------
		-- Processus BRC ET OutPut BRC
		-------------------------------------------------------------------------------------------------------------
		CycleBRC: process (CLK_1MHZ)

		variable tmpFht		: signed(16 downto 0)	:= (others => '0');	-- variable de calcul - FHT - valeur rÃ©el de -64738 Ã  +64737
		variable tmpFhst		: signed(21 downto 0)	:= (others => '0');	-- variable de calcul - valeur rÃ©el de -2097152 to +2097151
		variable tmpFz		: signed(10 downto 0)   := (others => '0');	-- variable de calcul - Fz temp réel
		begin 	  
			
			-- on met Ã  jour sur les flancs montants et descendants - avec INIT si CountStart=0 -------	 
			if (CLK_1MHZ='1' and CountStart ='0') then
				Fht <= "10000000000";
				Fhst <= "10011100000";	 								-- on initialise à -340 pour value -> directement
				Fzs <= Zmax_Vec;
				tmpFht := "00000000000000000";
				tmpFhst := "0000000000000000000000";
				tmpFz := "00000000000";
				CountStart <= '1';
				
			-- Horlogue de gestion BRC ---------------------------------------------------------------------------------
			else  
			-- Réalisation de la fonction BRC -- par cycle
				-- calcul Fzs - 
				if (Fht<500) then tmpFz := Zmax_Vec;
				else tmpFz := Zmin;
				end if;

				-- calcul Fht T1 - base
				tmpFht := resize(signed(Current_Vec),tmpFht'length) +  shift_left(signed(resize(Fht,tmpFht'length)- shift_left(resize(Fhst,tmpFht'length),2) - 3000),1);
				tmpFht := shift_right(signed((shift_left(tmpFht,1) + tmpFht)),2);
				
				if (tmpFht > 1023 ) then Fht <= "01111111111";
				elsif (tmpFht < -1024) then Fht <= "10000000000";
				else Fht <= tmpFht(10 downto 0);
				end if;

				
				-- calcul Fhst T1 -
				tmpFhst := resize(signed(Fhst),tmpFhst'length) - resize(signed(Fht),tmpFhst'length) ;
				tmpFhst := shift_right(resize((tmpFhst * resize(signed(tmpFz),tmpFhst'length)),tmpFhst'length),10) + resize(signed(Fht),tmpFhst'length) ;

				if (tmpFhst >1023) then Fhst <= "01111111111";
				elsif (tmpFhst< -800) then Fhst <= "10011100000";
				else Fhst <= tmpFhst(10 downto 0);
				end if;
		
				-- sortie vers out et DAC
				if (Fht>768) then Spike_O <= '1';
				else Spike_O <= '0';	 
				end if;
			
				Spike_Vec <= std_logic_vector(Fht(10 downto 0));

			end if;
		end process;
end architecture;	  


------------------------------------------------------------------
-- Définition de l'architecture neurone -> BURSTING             --
------------------------------------------------------------------
architecture B_BRC of brc_lib_pkg is 
	-------------------------------------------------------------
	-- DÃ©claration des variables et signaux internes processus --
	-------------------------------------------------------------
	-- Constants
	constant Zmin			: signed(20 downto 0)	:= "000000000000001100100"; 		-- !! valeur de Zmin - 100 par défaut - 	!!
																	-- !! durant un apprentissage 				!!
	-- Variables environnement - Gestion du BRC
	signal Fht			: signed(10 downto 0)	:= (others => '0');		-- variable H 	- valeur rÃ©el de -1024 Ã  + 1023	 
	signal Fhst			: signed(10 downto 0)	:= (others => '0');		-- variable Hs 	- valeur rÃ©el de -1024 Ã  + 1023
	signal Fzs			: signed(10 downto 0)	:= (others => '0');		-- variable zmax- valeur rÃ©el de -1024 Ã  + 1023
	signal BRcount		: signed(7 downto 0)	:= (others => '0');		-- variable de comptage temps pour bursting mode
								
	-- Variables environnement - DÃ©marrage - reset 
	signal CountStart 	: bit := '0' ;								-- dÃ©marrage avec initialisation
	
	begin 
		-------------------------------------------------------------------------------------------------------------
		-- Processus BRC ET OutPut BRC
		-------------------------------------------------------------------------------------------------------------
		CycleBRC: process (CLK_1MHZ)

		variable tmpFht		: signed(16 downto 0)	:= (others => '0');	-- variable de calcul - FHT - valeur rÃ©el de -64738 Ã  +64737
		variable tmpFhst		: signed(21 downto 0)	:= (others => '0');	-- variable de calcul - valeur rÃ©el de -2097152 to +2097151
		variable tmpFz		: signed(20 downto 0)	:= (others => '0');	-- variable de calcul - Fz temp réel		  
		variable tmpBrz		: signed(7  downto 0) := (others => '0');	-- variable de calcul - Brz
		variable tmpCurt 		: signed(10 downto 0) := (others => '0');	-- variable de calcul - variation de courant
		variable tmpdiffCur	: signed(10 downto 0) := (others => '0');	-- variable de calcul - variation de courant
		begin 	  
			
			-- on met Ã  jour sur les flancs montants et descendants - avec INIT si CountStart=0 -------	 
			if (CLK_1MHZ='1' and CountStart ='0') then
				Fht <= "10000000000";
				Fhst <= "10011100000";	 								-- on initialise à -800 pour value -> directement
				Fzs <= Zmax_Vec;
				tmpFht := "00000000000000000";
				tmpFhst := "0000000000000000000000";
				tmpFz := "000000000000000000000"; 
				tmpBrz := BRmin;
				BRcount <= BRmin;
				CountStart <= '1';
				
			-- Horlogue de gestion BRC ---------------------------------------------------------------------------------
			else  
			-- Réalisation de la fonction BRC -- par cycle
				-- calcul Fzs -	
				--tmpBrz := BRcount;
				if (BRset='1') then	
					-- mode BURSTING --
					tmpdiffCur := signed(Current_Vec) - tmpCurt;
					tmpCurt := signed (Current_Vec);
					if ((tmpdiffCur>100) or ( BRcount>BRmax)) then 
						tmpBrz := BRmin;
					end if;
					if (Fht>500) then
						tmpFz := resize(signed(Zmin),tmpFz'length);
					else			   
						tmpFz := shift_left(resize(signed(tmpBrz),tmpFz'length),3);
						if (tmpFz>+64) then tmpFz:="000000000000001000000"; end if;
						if (tmpFz<-64) then tmpFz:="111111111111111000000"; end if;
						tmpFz := resize(signed(BRZ_Vec),tmpFz'length) + resize(signed(shift_right(signed((signed(64 + tmpFz)*signed(resize(signed((Zmax_Vec)-signed(BRZ_Vec)),tmpFz'length)))),7)),tmpFz'length);
					end if;
					tmpBrz :=  tmpBrz + 1;  
					BRcount <= tmpBrz;
				else  
					-- mode SPIKING --
					if (Fht<500) then tmpFz := resize(signed(Zmax_Vec),tmpFz'length);
					else tmpFz := Zmin;
					end if;
			    	end if;	
				BRzv <= tmpFz;
	
				-- calcul Fht T1 - base
				tmpFht := resize(signed(Current_Vec),tmpFht'length) +  shift_left(signed(resize(Fht,tmpFht'length)- shift_left(resize(Fhst,tmpFht'length),2) - 3000),1);
				tmpFht := shift_right(signed((shift_left(tmpFht,1) + tmpFht)),2);
				
				if (tmpFht > 1023 ) then Fht <= "01111111111";
				elsif (tmpFht < -1024) then Fht <= "10000000000";
				else Fht <= tmpFht(10 downto 0);
				end if;

				
				-- calcul Fhst T1 -
				tmpFhst := resize(signed(Fhst),tmpFhst'length) - resize(signed(Fht),tmpFhst'length) ;
				tmpFhst := shift_right(resize((tmpFhst * resize(signed(tmpFz),tmpFhst'length)),tmpFhst'length),10) + resize(signed(Fht),tmpFhst'length) ;

				if (tmpFhst >1023) then Fhst <= "01111111111";
				elsif (tmpFhst< -800) then Fhst <= "10011100000";
				else Fhst <= tmpFhst(10 downto 0);
				end if;
		
				-- sortie vers out et DAC
				if (Fht>768) then Spike_O <= '1';
				else Spike_O <= '0';	 
				end if;
			
				Spike_Vec <= std_logic_vector(Fht(10 downto 0));

			end if;
		end process;
end architecture;
