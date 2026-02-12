-----------------------------------------------------------------------------
--
-- File : ExBinder-06.vhd
--
-- Description : VHDL source code for PLD or FPGA - Use to bind all packages 
--               and make a neurnal network - amélioration algo et correction erreurs
--
-- Chip : Unknow - devel.
--
-- Creation Date : May 10th, 2025
--
-- Last Modification Date : Novembre 12th, 2025
--
-- Last Modified by : Pascal Harmeling
--
-- update : fix display bug -> error to show the found number
-- Update : add Networklevel 'comparator' input integer vector - output position of the biggest value in the vector
-- Update : Bmac reduce 1 state -> 6 states 
-- WARNING : None
-----------------------------------------------------------------------------
--
-- FUNCTIONAL DESCRIPTION
-- 
--  
-- Requirements: input current 
--
-- Recent Updates	:	october 16th 2024
--
--   	- 
--     	- 	 
--	 	- 
--
-----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
-- Clock System
--use work.ClockSystem_pkg.all;

-- Sniffer -> display spiking matrix
--SIM_use work.BackGroundDisplay.all;
--SIM_work.Hub75Tm_pkg.all;

-- NetWork level 00
use work.WeightMatrix00.all;
use work.NEtWorkLevel00_pkg.all;

-- NetWork level 01
use work.WeightMatrix01.all;
use work.NEtWorkLevel01_pkg.all;

-- NetWork level 02
use work.WeightMatrix02.all;
use work.NEtWorkLevel02_pkg.all;

-- NetWork level 03
use work.WeightMatrix03.all;
use work.NEtWorkLevel03_pkg.all;

entity Exbinder02 is
     --generic(
     --   
     --   );
    
    Port (
        -- IO Système --
        CLK_Hz      : in std_logic

    );
end Exbinder02;

architecture Exbinder02_Full of Exbinder02 is
    -- display --
    signal Displm     : integer range 0 to ML00STM_L :=0;   -- Define number matrix spike trace display

    -- elements internes - RESET et Machinbe d'états
    signal reset      : std_logic :='0';  
    signal wreset     : integer range 0 to 8 := 0;      -- wait 8 machine cycles
    
    signal resetok    : std_logic_vector (4 downto 0) :="00000";  -- ensemble des reset périphérique processus enfant -> 4 networks
    
    signal Bmac       : integer range 0 to 7 ;           -- machine d'état pour le binder
                                                        -- State mac   : 0 - one wait cycle after a reset
											            -- 		       : 1 - Mode Ready
											            --			   : 2 - Mode Start
											            --			   : 4 - Mode compute
											            --			   : 5 - one wait cycle
						 					            --		       : 6 - Mode Latch
											            --			   : 7 - ending 
 
    signal ErrValueCMP: integer range 0 to 4000 :=0;       -- Compteur de bonne valeur
    signal INCCMP     : integer range 0 to 4000 :=0;       -- Compteur pure
    
    --signal MuRdataI   : std_logic_vector (0 to 1);         -- MicroMachine pour reset local + comparaison -> entrant FAIRE PASSER DANS TOUS LES NIVEAU
    signal MuRdataL0L1: std_logic_vector (0 to 5);         -- MicroMachine pour reset local + comparaison -> sortant du dernier niveau  
    signal MuRdataL1L2: std_logic_vector (0 to 5);         -- MicroMachine pour reset local + comparaison -> sortant du dernier niveau  
    signal MuRdataL2L3: std_logic_vector (0 to 5);         -- MicroMachine pour reset local + comparaison -> sortant du dernier niveau
    signal MuRdataL3  : std_logic_vector (0 to 5);         -- MicroMachine pour reset local + comparaison -> sortant du dernier niveau  
         
    -- element de jonction entre les niveaux
    signal L0L1		  : std_logic_vector ((ML00STM_X*ML00STM_Y)-1 downto 0);    -- signal de jonction entre Network 0 -> Network 1
    signal L1L2       : std_logic_vector (ML01X-1 downto 0);                    -- signal de jonction entre Network 1 -> Network 2
    signal L2L3       : int_array_ML02 := (0,0,0,0,0,0,0,0,0,0);                -- signal de jonction entre Network 2 -> Network 3
    signal L3L4       : integer range 0 to 9;                                   -- signal de jonction entre Network 2 -> Network 4
    
    -- element de communication entre les niveaux
    signal ReadyN     : std_logic_vector (3 downto 0) := "0000";         -- ensemble des ReadyN des périphériques et NetworkLxx
    signal Go         : std_logic := '0';                               -- active le calcul dans les différents niveaux
    signal Latch      : std_logic := '0';                               -- stockage des résultats dans les buffers des différents niveaux 
        
    ----------------------------------------------------------------------------------------------------------------------- debut de code  combinatoire et séquentiel --
    begin   
               
    -----------------------------------------------------------------------
	-- PACKAGE - NETWORK - active le niveau d'entrée                     --
	-----------------------------------------------------------------------  
    myNetWorkLevel00 :  NetWorkLevel00 port map(
                        Reset	=> 	reset,     		-- Reset all elements of on this level - Don't Forget Matrix
                        Resetok	=>  resetok(0),     -- Reset it's Done - RESET Value '0'
		
                        CLK		=> 	CLK_Hz,		    -- clock 
	
                        Go  	=> 	Go,           	-- start to compute !!!
                        Ready	=> 	ReadyN(0),      -- work is done - RESET Value '0' !!!
                        Latch	=> 	Latch,         	-- store results in a register !!!

                        MuR_outL0 => MuRdataL0L1,   -- MicroMachine pour reset local + comparaison -> sortant du dernier niveau
                        
                        MatrixNumber => Displm,     -- Step, size ...
                        Spike_I	=> (others=>'0'),   -- input previus level !!!
                        Spike_O	=> L0L1             -- output next level !!!
                  );
 
    -----------------------------------------------------------------------
	-- PACKAGE - NETWORK - active le niveau L1 du réseau de neurones     --
	----------------------------------------------------------------------- 
    myNetWorkLevel01 :  NetWorkLevel01 port map(
                        Reset	=> 	reset,     		-- Reset all elements of on this level - Don't Forget Matrix
                        Resetok	=>  resetok(1),     -- Reset it's Done - RESET Value '0'
		
                        CLK		=> 	CLK_Hz,		    -- clock 
	
                        Go  	=> 	Go,           	-- start to compute !!!
                        Ready	=> 	ReadyN(1),      -- work is done - RESET Value '0' !!!
                        Latch	=> 	Latch,         	-- store results in a register !!!

                        MuR_inL1  => MuRdataL0L1,     -- MicroMachine pour reset local + comparaison -> sortant du dernier niveau
                        MuR_outL1 => MuRdataL1L2,     -- MicroMachine pour reset local + comparaison -> sortant du dernier niveau

                        Spike_I	=>  L0L1,           -- input previus level !!!
                        Spike_O	=>  L1L2            -- output next level !!!
                  );
    
    -----------------------------------------------------------------------
	-- PACKAGE - NETWORK - active le niveau L2 du réseau de neurones     --
	-----------------------------------------------------------------------  
    myNetWorkLevel02 :  NetWorkLevel02 port map(
                        Reset	=> 	reset,     		-- Reset all elements of on this level - Don't Forget Matrix
                        Resetok	=>  resetok(2),     -- Reset it's Done - RESET Value '0'
		
                        CLK		=> 	CLK_Hz,		    -- clock 
	
                        Go  	=> 	Go,           	-- start to compute !!!
                        Ready	=> 	ReadyN(2),      -- work is done - RESET Value '0' !!!
                        Latch	=> 	Latch,         	-- store results in a register !!!

                        MuR_inL2  => MuRdataL1L2,     -- MicroMachine pour reset local + comparaison -> sortant du dernier niveau
                        MuR_outL2 => MuRdataL2L3,     -- MicroMachine pour reset local + comparaison -> sortant du dernier niveau

                        Spike_I	=> L1L2,            -- input previus level !!!
                        Spike_O	=> L2L3             -- output next level !!!
                  );
    
    -----------------------------------------------------------------------
	-- PACKAGE - NETWORK - active le niveau de sortie                    --
	-----------------------------------------------------------------------  
    myNetWorkLevel03 :  NetWorkLevel03 port map(
                        Reset	=> reset,     		-- Reset all elements of on this level - Don't Forget Matrix
                        Resetok	=> resetok(3),      -- Reset it's Done - RESET Value '0'
		
                        CLK		=> CLK_Hz,		    -- clock 
	
                        Go  	=> Go,           	-- start to compute !!!
                        Ready	=> ReadyN(3),       -- work is done - RESET Value '0' !!!
                        Latch	=> Latch,         	-- store results in a register !!!
 
                        MuR_inL3  => MuRdataL2L3,     -- MicroMachine pour reset local + comparaison -> sortant du dernier niveau
                        MuR_outL3 => MuRdataL3,     -- MicroMachine pour reset local + comparaison -> sortant du dernier niveau
   
                        Spike_I	=> ML03int_array(L2L3),            -- input previus level !!!
                        Spike_O	=> L3L4             -- output next level !!!
                  );
                        
    ------------------------------------------------
	-- Processus principal - BINDER               --
	------------------------------------------------  
    process(CLK_Hz, reset)
    begin 
        if rising_edge(CLK_Hz) then
            -- processus mode RESET --
            if reset='0' then
                reset<='0';
                if (wreset<8) then
                    wreset <= wreset +1;
                else
                    Displm <= 0;
                    BmaC <= 0;
                    Go <= '0';
                    Latch <='0';
                    wreset <= 0;
                    reset <= '1';
                  end if;  
            -- processus mode CONTINU --
            else
                case BmaC is
                    -- attendre que tous les processus enfants aient fini leur reset
                    when 0 =>
                        if (resetok="01111") then
                            BmaC <= 1;
                        end if;
                    -- wait 1 cycle --
                    when 1 =>
                        BmaC <= 2;
                    -- démarrage des processus enfants --                        
                    when 2 =>
                        Go <='1';
                        BmaC <= 3; 
                    -- wait 1 cycle --
                    when 3 =>
                        BmaC <= 4;                                
                   -- attendre que tous les processus enfants aient inhiber 'ready' -> off pour go =0
                    when 4 =>
                        if (ReadyN="0000") then
                            BmaC <= 5;
                            Go <='0';
                        end if;                            
                    -- attendre que tous les processus enfants aient activer 'ready' -> on pour activer latch
                    when 5 =>
                        if (ReadyN="1111") then
                            BmaC <= 6;
                            Latch <='1';
                        end if;                            
                    -- enregistrement des résusltats processus enfants dans les registres et
                    -- attendre que tous les readyN repasse à '0' -> indication latch terminé 
                    when 6 =>
                        if (ReadyN="0000") then
                            if (MuRdataL3(1) ='1') then
                                INCCMP <= INCCMP + 1; 
                                if (L3L4 /= to_integer(unsigned(MuRdataL3(2 to 5)))) then
                                    ErrValueCMP <= ErrValueCMP + 1;
                                 end if;
                            end if;   
                            if (MuRdataL2L3(0) ='1') then
                                BmaC <= 0;
                            else    
                                BmaC <= 1;
                            end if;
                            Latch <='0';
                            Displm <= Displm +1;
                            if Displm = (ML00STM_L-1) then
                                BmaC <= 7;
                                Displm <= (ML00STM_L-1);
                            end if;
                        end if;
                    when 7 =>
                    -- mort du processus - ending
                           BmaC <= 7;
                   end case;  
            end if;
        end if;
    end process;

end Exbinder02_Full;
