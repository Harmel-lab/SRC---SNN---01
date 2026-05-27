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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.WeightMatrix01.all;
use work.Src2F_Cbit_pkg.all;

package src_L01_pkg is
	component Src_neuro_L01
		port (
            CLK           	: IN std_logic; 									-- Master clock @ 1 MHz
            reset           : IN std_logic;                                     -- Reset
            go              : IN std_logic;                                     -- start processus
            ready           : OUT std_logic := '0';                             -- Processus terminé -> initialisation à 0 - pas prêt !!
            MuR_in          : in std_logic_vector (0 to 1);                    -- largueur du bus de données muMachine
        
            -- variables spécifiques --
            NumberCell      : integer range 0 to ML01X-1;                       -- numéro de cellule 
            Spike_I         : in std_logic_vector (ML01Y-1   downto 0);         -- input spike pulses
			Spike_O 	    : OUT std_logic									    -- Output spike pulses
			);
	end component;
end src_L01_pkg;

------------------------------------------------------------------
-- Definition des interconnexions -> SPIKING              		--
------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.WeightMatrix01.all;
use work.Src2F_Cbit_pkg.all;

entity Src_neuro_L01 is
	port (
        CLK           	: IN std_logic; 									-- Master clock @ 1 MHz
        reset           : IN std_logic;                                     -- Reset
        go              : IN std_logic;                                     -- start processus
        ready           : OUT std_logic := '0';                             -- Processus terminé -> initialisation à 0 - pas prêt !!
        MuR_in          : in std_logic_vector (0 to 1);                    -- largueur du bus de données muMachine
   
        -- variables spécifiques --
        NumberCell      : integer range 0 to ML01X-1;                       -- numéro de cellule 
        Spike_I         : in std_logic_vector (ML01Y-1   downto 0);         -- input spike pulses
        Spike_O 	    : OUT std_logic									    -- Output spike pulse
    );
end entity;

------------------------------------------------------------------
-- Definition de l'architecture neurone -> SPIKING              --
------------------------------------------------------------------
architecture SRC_all_L01 of Src_neuro_L01 is 
	--------------------------------------------------------------
	-- Déclaration des variables et signaux internes processus --
	--------------------------------------------------------------
	-- Constants
																			
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
    signal CurrentInt   : std_logic :='0';                              -- Current input INT [-1024 ... +1023]
    constant ML01       : framebuffer_ML01 :=ML01;                      -- matrice de poids 
    signal icur         : integer range 0 to ML01Y := 0;                -- variable de boucle somme courant
    signal clkSRC       : std_logic :='0';
    signal LSpike_O     : std_logic :='0';
    
	-------------------------------------------------------------
	-- Déclaration des Fonctions system                        --
	-------------------------------------------------------------  

	begin 
	-------------------------------------------------------------
	-- Generate compute's cells                                --
	-------------------------------------------------------------  
	u1 : entity work.OneSrc(OneSrc_all) port map( 
	                rst        => MuR_in(0), 
	                clk        => clkSRC,
	                CurrentInt => CurrentInt,
        
                    -- variables spécifiques --
                    outSp      => LSpike_O
                    );

		-------------------------------------------------------------------------------------------------------------
		-- Processus BRC ET OutPut BRC
		-------------------------------------------------------------------------------------------------------------
		Spike_O <= LSpike_O;
		
		CycleBRC: process (CLK, reset , go, CurrentInt)

		--variable local pour le processus de traitement de la tâche
		variable tmpcur     : integer range -50000 to +50000 :=0;   -- variable de calcul - Somme courant
		variable tmpcuru    : signed (15 downto 0);                 -- variable pour les shift
		variable tmpcurold  : integer range -50000 to +50000 :=0;	-- variable de calcul - Somme courant
		
        begin 	  
        if rising_edge(CLK) then
            -- processus mode RESET --
            if (reset='0') then
               SmaC <= 0;
                SmaInc <= 0;
                -- traitement du RESET --
                icur <= 0; 				
                tmpcur := 0;
                tmpcurold := 0;
                CurrentInt <= '0';
                clkSRC <= '0';
                
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
                        if (MuR_in(0)='1') then
                            icur <= 0; 				
                            tmpcur := 0;
                            tmpcurold := 0;
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
                                    if (tmpcur>0) then 
                                         CurrentInt<= '1';
                                    else 
                                         CurrentInt<= '0';
                                    end if;
                                
                                    SmaInc<=2;
                                -- faire buffer Current ... 
                                when 2 =>
                                   clkSRC <= '1';
                                   SmaInc<=3;
                                
                                -- faire Calcul de Fh Fhs ... 
                                when 3 =>
                                  clkSRC <= '0';                             
                                  -- transfert buffer --
                                
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
    end process;			
end SRC_all_L01;	  