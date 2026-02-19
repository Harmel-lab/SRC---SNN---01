-----------------------------------------------------------------------------
--
-- File : Neuron-BRamInLine_pkg.vhd
--
-- Description : VHDL source code for PLD or FPGA - spike generator - Library
--
-- Chip : Unknow - devel.
--
-- Creation Date : July 25th, 2025
--
-- Last Modification Date : July 25th, 2025
--
-- Last Modified by : Pascal Harmeling
--									   
-- WARNING : None
-----------------------------------------------------------------------------
--
-- FUNCTIONAL DESCRIPTION
-- 
--  
-- Requirements: initialization file *.COE
--
-- Recent Updates
--
-- July 25th, 2025
--		- mise en place de la architecture InLine_BRam et premier tests
----------------------------------------------------------------------------- 
-- remarques:
--
------------------------------------pascal.harmeling@uliege.be---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.WeightMatrix00.all;

package Neuron_BramInLine_pkg is
	component Neuron_BramInLine
		port (
            CLK           	: IN std_logic; 									-- Master clock @ 1 MHz
            reset           : IN std_logic;                                     -- Reset
            go              : IN std_logic;                                     -- start processus
            ready           : OUT std_logic := '0';                             -- Processus terminé -> initialisation à 0 - pas prêt !!
        
            -- variables spécifiques --
            BRaddr            : IN integer range 0 to (ML00STM_L-1);                   -- bus d'adresse (total 221 registres)
            BRdata_out        : OUT std_logic_vector (0 to (ML00STM_X*ML00STM_Y)-1);   -- largueur du bus de données en sortie
            BRNumC_out        : OUT std_logic_vector (0 to 3);                         -- largueur du bus de données chiffre de comparaison
            BRMuR_out         : OUT std_logic_vector (0 to 1)                          -- largueur du bus de données muMachine
            
     		);
	end component;
end Neuron_BramInLine_pkg;

------------------------------------------------------------------
-- Definition des interconnexions -> SPIKING              		--
------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.WeightMatrix00.all;

entity Neuron_BramInLine is
	port (
            CLK           	: IN std_logic; 									-- Master clock @ 1 MHz
            reset           : IN std_logic;                                     -- Reset
            go              : IN std_logic;                                     -- start processus
            ready           : OUT std_logic := '0';                             -- Processus terminé -> initialisation à 0 - pas prêt !!
        
            -- variables spécifiques --
            BRaddr            : IN integer range 0 to (ML00STM_L-1);                  -- bus d'adresse (total 221 registres)
            BRdata_out        : OUT std_logic_vector (0 to (ML00STM_X*ML00STM_Y)-1);  -- largueur du bus de données en sortie
            BRMuR_out         : OUT std_logic_vector (0 to 5)                                 
     		);
    
end entity;

------------------------------------------------------------------
-- Definition de l'architecture neurone -> SPIKING              --
------------------------------------------------------------------
architecture Neuron_BramInLine_all of Neuron_BramInLine is 
	------------------------------------------------------------------------
	-- Déclaration du composant pour le chargement des valeur via IP      --
	------------------------------------------------------------------------	
	component BramROM_ip is 
	   port (
			clka      	    : IN std_logic; 								    -- Master clock @ 1 MHz
            addra           : IN std_logic_vector(16 DOWNTO 0);                  -- bus d'adresse (total 221 registres)
            douta           : OUT std_logic_vector (0 to 789)                   -- largueur du bus de données en sortie      
        );
    end component;
    
	--------------------------------------------------------------
	-- Déclaration des variables et signaux internes processus --
	--------------------------------------------------------------
	-- Constants
																							-- !! durant un apprentissage 				!!
	-- Variables environnement - Gestion du Lintégrator
    signal SmaC       : integer range 0 to 4 := 0;   -- State mac  : 0 - attendre Go = 0
											         -- 		   : 1 - attendre GO = 1 -> ready =0
											         --			   : 2 - FAIRE LA TACHE PROCESSUS - boucle de production et traitement des datas
											         --			   : 4 - indiquation Fin de tâche -> ready =1 et boucle SmaC en '00'
   	
	-- Variables environnement - Gestion global
    signal valdata  : std_logic_vector (0 to 789);
	signal convadd  : std_logic_vector(16 DOWNTO 0);
	   
    -- Variable pour le processus de traitement de la tâche
    
	-------------------------------------------------------------
	-- Déclaration des Fonctions system                        --
	-------------------------------------------------------------  

	begin 
        BramROM_ip_instance : BramROM_ip
            port map (
               clka    => CLK,
               addra   => convadd,
               douta   => valdata
            );  	   

 		-------------------------------------------------------------------------------------------------------------
		-- Processus Lecture BRAM
		-------------------------------------------------------------------------------------------------------------
		CycleLInt: process (CLK,Reset, go)
		--variable local pour le processus de traitement de la tâche
        
        begin 	  
        if rising_edge(CLK) then
            -- processus mode RESET --
            if (reset='0') then
                SmaC <= 0;
                -- traitement du RESET --
                BRdata_out <=(others => '0');       -- Efface toutes les données de sortie
                BRMuR_out <=(others => '0');        -- "
                
                convadd <=(others => '0');          -- reset de l'adresse utilisée pour lire la BRAM         
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
                           SmaC<=2;
                       end if;
                    -- réalisation de la tâche ; si fin -> next
                    when 2 =>
                        -- réalisation de la tâche -> donne l'adresse à la BRAM
                        convadd  <= std_logic_vector(to_unsigned(BRaddr, 17));
                        SmaC<=3;
                    when 3 =>
                        -- réalise un Wait        
                        SmaC<=4;
                   -- assigne le buffer de sortie et indiquation ready --
                    when 4 =>
                        ready <= '1';
                        BRdata_out <= valdata(6 to 789);
                        BRMuR_out  <= valdata(0 to 5);
                        SmaC<=0;
                end case;
            end if;
        end if;
    end process;
           
end Neuron_BramInLine_all;	  