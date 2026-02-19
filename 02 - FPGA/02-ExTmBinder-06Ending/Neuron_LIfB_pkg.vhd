-----------------------------------------------------------------------------
--
-- File : LIntSpike_pkg.vhd
--
-- Description : VHDL source code for PLD or FPGA - spike generator - Library
--
-- Chip : Unknow - devel.
--
-- Creation Date : April 26th, 2025
--
-- Last Modification Date : may firs, 2025
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
use work.WeightMatrix02.all;
use work.WeightMatrix03.all;

package LInt_neuro_pkg is
	component LInt_neuro
		port (
			CLK      	    : IN std_logic; 								    -- Master clock @ 1 MHz
            reset           : IN std_logic;                                     -- Reset
            go              : IN std_logic;                                     -- start processus
            ready           : OUT std_logic;                                    -- Processus terminé
            MuR_inL         : in std_logic_vector (0 to 1);                    -- largueur du bus de données muMachine

            -- variables spécifiques --
            NumberCell      : integer range 0 to ML02X-1;                       -- numéro de cellule 
            Spike_I		    : IN std_logic_vector (ML02Y-1   downto 0);         -- all input spikes
            Spike_O 	    : OUT integer range ML03Minval to ML03Maxval := 0   		    -- Output spike pulse
 		 );
	end component;
end LInt_neuro_pkg;

------------------------------------------------------------------
-- Definition des interconnexions -> SPIKING              		--
------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.WeightMatrix02.all;
use work.WeightMatrix03.all;

entity LInt_neuro is
	port (
        CLK           	: IN std_logic; 									-- Master clock @ 1 MHz
        reset           : IN std_logic;                                     -- Reset
        go              : IN std_logic;                                     -- start processus
        ready           : OUT std_logic := '0';                             -- Processus terminé -> initialisation à 0 - pas prêt !!
        MuR_inL         : in std_logic_vector (0 to 1);                    -- largueur du bus de données muMachine

        -- variables spécifiques --
        NumberCell      : integer range 0 to ML02X-1;                       -- numéro de cellule 
        Spike_I		    : IN std_logic_vector (ML02Y-1   downto 0);         -- all input spikes
        Spike_O 	    : OUT integer range ML03Minval to ML03Maxval := 0   	    -- Output spike pulse -> valeur de l'intégration
         );
    
end entity;

------------------------------------------------------------------
-- Definition de l'architecture neurone -> Lif without Reset    --
------------------------------------------------------------------
architecture LInt_neuro_all of LInt_neuro is 
	--------------------------------------------------------------
	-- Déclaration des variables et signaux internes processus --
	--------------------------------------------------------------
	-- Constants
																							-- !! durant un apprentissage 				!!
	-- Variables environnement - Gestion du Lintégrator
	signal tmpcurSUP  : integer range -1024 to +1023 :=0;
    signal SmaC       : integer range 0 to 3 := 0;   -- State mac  : 0 - attendre Go = 0
											         -- 		   : 1 - attendre GO = 1 -> ready =0
											         --			   : 2 - FAIRE LA TACHE PROCESSUS - boucle de production et traitement des datas
											         --			   : 4 - indiquation Fin de tâche -> ready =1 et boucle SmaC en '00'

    signal SmaInc     : integer range 0 to 2 := 0;   -- State mac  : 0 - réalisation somme courant
                                                     --            : 2 - <<5
                                                     --            : 3 - boucle de feetback ( it = somm() + (it'-(it'>>4 + it'>>5)) )
                                                     --            : 4 - Calcul de Fh Fhs ... 
   	
	-- Variables environnement - Démarrage - reset 
	constant ML02       : framebuffer_ML02 :=ML02;                      -- matrice de poids 

    signal icur         : integer range 0 to ML02Y := 0;                -- variable de boucle somme courant
	
	-------------------------------------------------------------
	-- Déclaration des Fonctions system                        --
	-------------------------------------------------------------  
	begin 
		-------------------------------------------------------------------------------------------------------------
		-- Processus LIF without Reset
		-------------------------------------------------------------------------------------------------------------
		CycleLInt: process (CLK,Reset, go)
		--variable local pour le processus de traitement de la tâche
		variable tmpcur     : integer range -2048 to +2047 :=0;   -- variable de calcul - Somme courant
        
        begin 	  
        if rising_edge(CLK) then
            -- processus mode RESET --
            if (reset='0') then
                SmaC <= 0;
                -- traitement du RESET --
                tmpcur := 0;
                Spike_O <= 0;
                icur <=0;
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
                           icur<=0; 
                           SmaInc<=0;
                           SmaC<=2;
                       end if;
                    -- réalisation de la tâche ; si fin -> next
                    when 2 =>
                        if (MuR_inL(0)='1') then
                            tmpcur := 0;
                            Spike_O <= 0;
                            icur <=0;
                            SmaC<=3;
                        else
                            -- réalisation de la tâche
                            -- réalisation de la tâche - add du courant -> courant global -> Z, h et hs
                            case SmaInc is
                                -- faire somme LIF --
                                when 0 =>
                                    if icur<ML02Y then
                                        if (Spike_I(icur)='1') then
                                            if ML02(NumberCell,icur) ='1' then
                                                tmpcur := tmpcur + ML02Val1;
                                            else
                                                tmpcur := tmpcur + ML02Val0;
                                            end if;
                                        end if;      
                                      tmpcurSUP <= tmpcur;
                                      icur<= icur+1;
                                     else 
                                        SmaInc<=1;
                                    end if;
                                 -- faire <<5 + (it'-(it'>>4 + it'>>5))
                                 when 1 =>
                                    Spike_O <= tmpcur ;
                                    SmaInc<=2;
                                 -- faire Calcul de Fh Fhs ... 
                                 when 2 => 
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
    end process;
    			
end LInt_neuro_all;	  