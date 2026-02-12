-----------------------------------------------------------------------------
--
-- File : Src-Neuron_pkg.vhd
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
-----------------------------------------------------------------------------
--
-- FUNCTIONAL DESCRIPTION
-- 
--  
-- Requirements: input current 
--
-- Recent Updates
--
--     	- Librairie pour BRC mode spiking et bursting.
--     	- Optimisation du code.
--	   	- Suppression des cycles d'horloge -> ajout Variables
--     	- Suppression du processe de gestion output et DAC
--	   	- Suppression de la constante Zmax_max
-- December 29th 2024
--		- Fix Bugs and reduce size of all buffers to well manage memories
-- January 2th 2025
--		- bursting code - first test
-- April first
--      - mise en forme package
-- April 25th
--		- mise en place de la somme
----------------------------------------------------------------------------- 
-- remarques:
--       - a vérifier : Fzt n'est pas un registre utile -> à effecer?
--       - possible erreur dans l'odre des opération sur le calcul de tmppFz!
--
------------------------------------pascal.harmeling@uliege.be---------------
-- Voir Article sur la SFA (spiking frequency adaptation)
--                          ----------------------------
--
-- !! durant un apprentissage 				!!
-- !! courant de flux pour bursting 		!!
-- !!  01110000100 = 900		*			!!
-- !!  01110110110 = 950					!!
-- !!  01111010100 = 980					!!
-- !!  01111101000 = 1000					!!
-- !!  01111110010 = 1010					!! 
-- !!  01111111100 = 1020					!!
 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.WeightMatrix01.all;

package src_pkg is
	component Src_neuro
		port (
            CLK           	: IN std_logic; 									-- Master clock @ 1 MHz
            reset           : IN std_logic;                                     -- Reset
            go              : IN std_logic;                                     -- start processus
            ready           : OUT std_logic := '0';                             -- Processus terminé -> initialisation à 0 - pas prêt !!
            MuR_inL         : in std_logic_vector (0 to 1);                    -- largueur du bus de données muMachine
        
            -- variables spécifiques --
            NumberCell      : integer range 0 to ML01X-1;                       -- numéro de cellule 
            Spike_I         : in std_logic_vector (ML01Y-1   downto 0);         -- input spike pulses
			Spike_O 	    : OUT std_logic									    -- Output spike pulses
			);
	end component;
end src_pkg;

------------------------------------------------------------------
-- Definition des interconnexions -> SPIKING              		--
------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.WeightMatrix01.all;

entity Src_neuro is
	port (
        CLK           	: IN std_logic; 									-- Master clock @ 1 MHz
        reset           : IN std_logic;                                     -- Reset
        go              : IN std_logic;                                     -- start processus
        ready           : OUT std_logic := '0';                             -- Processus terminé -> initialisation à 0 - pas prêt !!
        MuR_inL         : in std_logic_vector (0 to 1);                    -- largueur du bus de données muMachine
   
        -- variables spécifiques --
        NumberCell      : integer range 0 to ML01X-1;                       -- numéro de cellule 
        Spike_I         : in std_logic_vector (ML01Y-1   downto 0);         -- input spike pulses
        Spike_O 	    : OUT std_logic									    -- Output spike pulse
    );
end entity;

------------------------------------------------------------------
-- Definition de l'architecture neurone -> SPIKING              --
------------------------------------------------------------------
architecture SRC_all of Src_neuro is 
	--------------------------------------------------------------
	-- Déclaration des variables et signaux internes processus --
	--------------------------------------------------------------
	-- Constants
	constant Zmin		: unsigned(9 downto 0)	:= "0001100100";     --"0001100100"; 		-- !! valeur de Zmin - 100 par d�faut - 	!!
	constant Zmax       : unsigned(9 downto 0)	:= "1110000100";     --"1100100000"; 		-- !! valeur de Zmin - 800             - 	!!
	                                                                 --"1101010010"; 		-- !! valeur de Zmin - 850             - 	!!
	                                                                 --"1101011100"; 		-- !! valeur de Zmin - 860             - 	!!
	                                                                 --"1101100110"; 		-- !! valeur de Zmin - 870             - 	!!
	                                                                 --"1101110000"; 		-- !! valeur de Zmin - 880             - 	!!
	                                                                 --"1101110101"; 		-- !! valeur de Zmin - 885             - 	!!
	                                                                 --"1101111010"; 		-- !! valeur de Zmin - 890             - 	!!
	                                                                 --"1110000100"; 		-- !! valeur de Zmin - 900             - 	!!
	                                                                 --"1110001110"; 		-- !! valeur de Zmin - 910             - 	!!
	                                                                 --"1110011000"; 		-- !! valeur de Zmin - 920 par d�faut - 	!!
	                                                                 --"1110100010"; 		-- !! valeur de Zmin - 930             - 	!!
	                                                                 --"1110101100"; 		-- !! valeur de Zmin - 940             - 	!!
	                                                                 --"1110110110"; 		-- !! valeur de Zmin - 950             - 	!!
	                                                                 --"1111000000"; 		-- !! valeur de Zmin - 960             - 	!!
	                                                                 --"1111001010"; 		-- !! valeur de Zmin - 970             - 	!!
	                                                                 --"1111010100"; 		-- !! valeur de Zmin - 980             - 	!!
	   																 --"1111011110"; 		-- !! valeur de Zmin - 990             - 	!!
	   																 --"1111101000"; 		-- !! valeur de Zmin - 1000             - 	!!
	   																 		
	-- Variables environnement - Gestion global
    signal SmaC         : integer range 0 to 3 := 0;   -- State mac  : 0 - attendre Go = 0
											           -- 		     : 1 - attendre GO = 1 -> ready =0
											           --			 : 2 - FAIRE LA TACHE PROCESSUS - boucle de production et traitement des datas
											           --			 : 3 - indiquation Fin de tâche -> ready =1 et boucle SmaC en '00'
											         
    signal SmaInc       : integer range 0 to 3 := 0;   -- State mac  : 0 - réalisation somme courant
                                                       --            : 1 - <<5
                                                       --            : 2 - buffer current
                                                       --            : 3 - Calcul de Fh Fhs ... 
                            
	-- -- Variable pour le processus de traitement de la tâche - Gestion du BRC
    signal CurrentInt   : integer range -1024 to +1023 := 0;            -- Current input INT [-1024 ... +1023]
    signal Fht			: signed(10 downto 0)	:= (others => '0');		-- variable H 	- valeur réel de -1024 à + 1023
	signal Fhst			: signed(10 downto 0)	:= (others => '0');		-- variable Hs 	- valeur réel de -1024 à + 1023
	signal Fz		    : unsigned(9 downto 0)  := (others => '0');	    -- variable de calcul - Fz temp réel
    constant ML01       : framebuffer_ML01 :=ML01;                      -- matrice de poids 

    signal icur         : integer range 0 to ML01Y := 0;                  -- variable de boucle somme courant
    
    signal infotmpcur   : integer range -30000 to +30000 :=0;
    
	-------------------------------------------------------------
	-- Déclaration des Fonctions system                        --
	-------------------------------------------------------------  

	begin 
		-------------------------------------------------------------------------------------------------------------
		-- Processus BRC ET OutPut BRC
		-------------------------------------------------------------------------------------------------------------
		CycleBRC: process (CLK, reset , go, Fht, Fhst, CurrentInt)

		--variable local pour le processus de traitement de la tâche
		variable tmpcur     : integer range -30000 to +30000 :=0;   -- variable de calcul - Somme courant
		variable tmpcuru    : signed (15 downto 0);                 -- variable pour les shift
		variable tmpcurold  : integer range -30000 to +30000 :=0;	-- variable de calcul - Somme courant
		
        -----!variable icur       : integer range 0 to ML01Y := 0;      -- variable de boucle somme courant
        
		variable tmpFz		: unsigned(9 downto 0)  := (others => '0');	-- variable de calcul - Fz temp réel        	
		variable tmpFht	    : signed(16 downto 0)	:= (others => '0');	-- variable de calcul - FHT - valeur réel de -64738 à +64737
		variable tmpFhst	: signed(21 downto 0)	:= (others => '0');	-- variable de calcul - valeur réel de -2097152 to +2097151
        
        begin 	  
        if rising_edge(CLK) then
            -- processus mode RESET --
            if (reset='0') then
                SmaC <= 0;
                SmaInc <= 0;
                -- traitement du RESET --
                Fht <= "00000000000";
                Fhst <= "00000000000";
                icur <= 0; 				
                tmpFht := "00000000000000000";
                tmpFhst := "0000000000000000000000";
                tmpFz := "0000000000";
                tmpcur := 0;
                tmpcurold := 0;
                CurrentInt <= 0;
                
                -- fin de traitement du RESET --
                ready <= '1';
            
			-- Horlogue de gestion BRC -----------------------------------------------------------------
           -- processus mode state Machine SmacC --
            else
                case SmaC is
                    -- attendre que GO passe à 0 --
                    when 0 =>
                       if go='0' then
                           SmaC<=1;
                       end if;
                    -- attendre que GO passe à 1 --
                    when 1 =>
                       if go='1' then
                           ready <= '0';
                           -- initialisation préparation du processus de traitement -- 
                           SmaC<=2;
                           SmaInc<=0;
                           icur<=0;
                           tmpcurold := tmpcur;
                           tmpcur:=0;
                       end if;
                    -- réalisation de la tâche ; si fin -> next
                    when 2 =>
                        if (MuR_inL(0)='1') then
                            Fht <= "00000000000";
                            Fhst <= "00000000000";
                            icur <= 0; 				
                            tmpFht := "00000000000000000";
                            tmpFhst := "0000000000000000000000";
                            tmpFz := "0000000000";
                            tmpcur := 0;
                            tmpcurold := 0;
                            CurrentInt <= 0;
                            SmaC<=3;
                        else    
                        -- réalisation de la tâche - add du courant -> courant global -> Z, h et hs
                           case SmaInc is
                                -- faire somme courant --
                                when 0 =>
                                    if icur<ML01Y then
                                        -- faire la somme PART 1
                                        if (Spike_I(icur)='1') then
                                            tmpcur := tmpcur + ML01(NumberCell,icur);
                                        end if;      
                                        -- faire la somme PART 2
                                        if (Spike_I(icur+1)='1') then
                                            tmpcur := tmpcur + ML01(NumberCell,(icur+1));
                                        end if;      
                                        -- faire la somme PART 3
                                        if (Spike_I(icur+2)='1') then
                                            tmpcur := tmpcur + ML01(NumberCell,(icur+2));
                                        end if;      
                                        -- faire la somme PART 4
                                        if (Spike_I(icur+3)='1') then
                                            tmpcur := tmpcur + ML01(NumberCell,(icur+3));
                                        end if;      
                                        -- faire la somme PART 5
                                       if (Spike_I(icur+4)='1') then
                                            tmpcur := tmpcur + ML01(NumberCell,(icur+4));
                                        end if;      
                                        -- faire la somme PART 
                                        if (Spike_I(icur+5)='1') then
                                            tmpcur := tmpcur + ML01(NumberCell,(icur+5));
                                        end if;      
                                        -- faire la somme PART 1
                                        if (Spike_I(icur+6)='1') then
                                            tmpcur := tmpcur + ML01(NumberCell,(icur+6));
                                        end if;      
                                        -- faire la somme PART 1
                                        if (Spike_I(icur+7)='1') then
                                            tmpcur := tmpcur + ML01(NumberCell,(icur+7));
                                        end if;      
                                        
                                        icur<= icur+8;
                                     else 
                                        SmaInc<=1;
                                    end if;
                                 -- faire <<5 + (it'-(it'>>4 + it'>>5))
                                 when 1 =>
                                    tmpcuru := shift_right(to_signed(tmpcurold, tmpcuru'length),4);
                                    tmpcur := (tmpcurold - (to_integer(shift_right(tmpcuru,1))+ to_integer(tmpcuru))) + tmpcur ;
                                    infotmpcur<=tmpcur;
                                    if (tmpcur>0) then 
                                         CurrentInt<= +1023;
                                    else 
                                         CurrentInt<= -1024;
                                    end if;
                                
                                    SmaInc<=2;
                                 -- faire buffer Current ... et Fz 
                                 when 2 =>
                                    -- faire calcul de Zreel
                                    if (Fht<500) then tmpFz := Zmax ;
                                    else tmpFz := Zmin;
                                    end if;
                                    Fz<=tmpFz;
                                    SmaInc<=3;
                                    
                                 -- faire Calcul de Fh Fhs ... 
                                 when 3 =>
                                    -- calcul Fht  - base CurrentInt
                                    -- tmpFht := resize(signed(CurrentVec),tmpFht'length) +  shift_left(signed(resize(Fht,tmpFht'length)- shift_left(resize(Fhst,tmpFht'length),2) - 3000),1);
                                    tmpFht := CurrentInt +  shift_left(( resize(Fht,tmpFht'length) - shift_left(resize(Fhst,tmpFht'length),2) - 3000),1);
                                    tmpFht := shift_right((shift_left(tmpFht,1) + tmpFht),2);
                    
                                    -- calcul Fhst -
                                    tmpFhst := resize(Fhst,tmpFhst'length) - resize(Fht,tmpFhst'length) ;
                                    tmpFhst := shift_right(resize((tmpFhst * signed(resize(tmpFz,tmpFhst'length))),tmpFhst'length),10) + resize(Fht,tmpFhst'length) ;		
      
                                    -- mise à jour des variable principales
                                    if (tmpFht > 1023 ) then Fht <= "01111111111";
                                    elsif (tmpFht < -1024) then Fht <= "10000000000";
                                    else Fht <= tmpFht(10 downto 0);
                                    end if;
                             
                                    if (tmpFhst >1023) then Fhst <= "01111111111";
                                    elsif (tmpFhst< -800) then Fhst <= "10011100000";
                                    else Fhst <= tmpFhst(10 downto 0);
                                    end if;
                                                                
                                   -- si fin -> next
                                   SmaC<=3;
                           end case; 
                        end if;
                           
                     -- assigne le buffer de sortie et indiquation ready --
                    when 3 =>
                        ready <= '1';
                        SmaC<=0;
                end case;
            end if;
       
  
        end if;
        
 
       -- positionner la sortie
        Spike_O <= Fht(9) and not(Fht(10));

    end process;			
end SRC_all;	  