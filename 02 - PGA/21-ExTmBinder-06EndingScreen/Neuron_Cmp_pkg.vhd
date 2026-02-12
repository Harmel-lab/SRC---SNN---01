-----------------------------------------------------------------------------
--
-- File : Neuron_Cmp_pkg.vhd
--
-- Description : VHDL source code for PLD or FPGA - spike generator - Library
--
-- Chip : Unknow - devel.
--
-- Creation Date : MAY 22th, 2025
--
-- Last Modification Date : MAY 22th, 2025
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
----------------------------------------------------------------------------- 
-- remarques:
--
------------------------------------pascal.harmeling@uliege.be---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.WeightMatrix03.all;

package Cmp_neuro_pkg is   
	component Cmp_neuro
		port (
			CLK      	    : IN std_logic; 								    -- Master clock @ 1 MHz
            reset           : IN std_logic;                                     -- Reset
            go              : IN std_logic;                                     -- start processus
            ready           : OUT std_logic;                                    -- Processus terminé
            MuR_inL         : in std_logic_vector (0 to 1);                    -- largueur du bus de données muMachine

            -- variables spécifiques --
            NumberCell      : integer range 0 to ML03X-1;                       -- numéro de cellule 
            Spike_I		    : IN ML03int_array;                                 -- all input spikes
            Spike_O 	    : OUT integer range 0 to 9 := 0   		            -- Output spike pulse
 		 );
	end component;
end Cmp_neuro_pkg;

------------------------------------------------------------------
-- Definition des interconnexions -> SPIKING              		--
------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.WeightMatrix03.all;

entity Cmp_neuro is
	port (
        CLK           	: IN std_logic; 									-- Master clock @ 1 MHz
        reset           : IN std_logic;                                     -- Reset
        go              : IN std_logic;                                     -- start processus
        ready           : OUT std_logic := '0';                             -- Processus terminé -> initialisation à 0 - pas prêt !!
        MuR_inL         : in std_logic_vector (0 to 1);                    -- largueur du bus de données muMachine
 
        -- variables spécifiques --
        NumberCell      : integer range 0 to ML03X-1;                       -- numéro de cellule 
        Spike_I		    : IN ML03int_array;                                 -- all input spikes
        Spike_O 	    : OUT integer range 0 to 9 := 0   		            -- Output spike pulse
         );
    
end entity;

------------------------------------------------------------------
-- Definition de l'architecture neurone -> Lif without Reset    --
------------------------------------------------------------------
architecture Cmp_neuro_all of Cmp_neuro is 
	--------------------------------------------------------------
	-- Déclaration des variables et signaux internes processus --
	--------------------------------------------------------------
	-- Constants
																							-- !! durant un apprentissage 				!!
	-- Variables environnement - Gestion du la machine d'état de base
    signal SmaC       : integer range 0 to 3 := 0;   -- State mac  : 0 - attendre Go = 0
											         -- 		   : 1 - attendre GO = 1 -> ready =0
											         --			   : 2 - FAIRE LA TACHE PROCESSUS - boucle de production et traitement des datas
											         --			   : 4 - indiquation Fin de tâche -> ready =1 et boucle SmaC en '00'
   	
	-- Variables environnement - Gestion du la machine d'état de la fonction et des variables utiles
    signal SmaInc     : integer range 0 to 10 := 0;  -- State mac utilisateur  : 0 - attendre Go = 0 ... 
    signal outcmp     : integer range 0 to 10 := 0;
    signal MaxCmp     : ML03bounded_int;      
	
	-------------------------------------------------------------
	-- Déclaration des Fonctions system                        --
	-------------------------------------------------------------  
	begin 
		-------------------------------------------------------------------------------------------------------------
		-- Processus LIF without Reset
		-------------------------------------------------------------------------------------------------------------
		CycleLInt: process (CLK,Reset, go)
		--variable local pour le processus de traitement de la tâche
		variable tmpcur     : ML03bounded_int :=0;    -- variable de calcul - comparateur
        
        begin 	  
        if rising_edge(CLK) then
            -- processus mode RESET --
            if reset='0' then
                SmaC <= 0;
                -- traitement du RESET --
                SmaInc  <= 1;
                outcmp <= 0;
                MaxCmp  <=0;      
                -- fin de traitement du RESET --
                ready <= '1';
  
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
                           -- fin de traitement du RESET --
                           ready <= '0';
                           -- initialisation préparation du processus de traitement -- 
                           SmaInc  <= 1;
                           outcmp <= 0;
                           MaxCmp  <= Spike_I(0);      
                           SmaC<=2;
                       end if;
                    -- réalisation de la tâche ; si fin -> next
                    when 2 =>
                        if (MuR_inL(0)='1') then
                            SmaInc  <= 1;
                            outcmp <= 0;
                            MaxCmp  <=0;
                            SmaC<=3;   
                        else
                           -- réalisation de la tâche - comparateur sur n nombre 
                            if SmaInc<ML03Y then
                                SmaInc <= SmaInc + 1;
                                -- faire la Comparaison
                                if Spike_I(SmaInc)>MaxCmp then
                                    MaxCmp <= Spike_I(SmaInc);
                                    outcmp <= SmaInc;
                                end if;
                            else
                                Spike_O <= outcmp;
                                SmaC<=3;
                            end if;
                       end if;
                    -- assigne le buffer de sortie et indiquation ready --
                    when 3 =>
                       ready <= '1';
                       SmaC<=0;
                end case;
            end if;
        end if;
    end process;			
end Cmp_neuro_all;	  