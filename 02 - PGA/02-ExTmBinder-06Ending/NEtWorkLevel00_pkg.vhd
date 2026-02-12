-----------------------------------------------------------------------------
--
-- File : NetWorkLevel01.vhd
--
-- Description : VHDL source code for PLD or FPGA - Use to bind all packages 
--               and make a neurnal network
--
-- Chip : Unknow - devel.
--
-- Creation Date : april 23th, 2025
--
-- Last Modification Date : april 23th, 2025
--
-- Last Modified by : Pascal Harmeling
--
-- update : Set Network Level xx - spiking neuronal netwrk 
--               - mise en place du la couche d'interface standard
--               - mise en place machine d'états Reset, Goc and Latch
-- Update : 
-- Update : 
	
-- WARNING : None
-----------------------------------------------------------------------------
--
-- FUNCTIONAL DESCRIPTION
-- 
--  
-- Requirements: Weight W matrix
--
--
-----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library unisim;  -- Ajoute la bibliothèque unisim
use unisim.vcomponents.all;  -- Importer tous les composants de unisim (dont IBUFGDS)

library work;
use work.WeightMatrix00.all;
use work.WeightMatrix01.all;
use work.Neuron_BramInLine;

package NetWorkLevel00_pkg is
    component NetWorkLevel00
        Port (
            -- Reset --
            Reset		: in std_logic;			-- Reset all elements of on this level - Don't Forget Matrix
            Resetok		: out std_logic := '0'; -- Reset it's Done - RESET Value '0'
            
            -- set machine --
            CLK         : in std_logic;			-- clock 
            Go  		: in std_logic;			-- start to compute
            Ready		: out std_logic := '0';	-- work is done - RESET Value '0'
            Latch		: in std_logic;			-- store results in a register   
            MuR_outL0   : OUT std_logic_vector (0 to 5);                    -- largueur du bus de données muMachine

            -- Data Level Input-Output
	 	    MatrixNumber: integer range 0 to (ML00STM_L-1) :=0; 
            Spike_I		: IN std_logic_vector (ML01Y-1   downto 0);
            Spike_O		: OUT std_logic_vector ((ML00STM_X*ML00STM_Y)-1 downto 0)
            );
    end component;
end NetWorkLevel00_pkg;

------------------------------------------------------------------
-- Definition des interconnexions -> NetWorkLevel01       		--
------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library unisim;  -- Ajoute la bibliothèque unisim
use unisim.vcomponents.all;  -- Importer tous les composants de unisim (dont IBUFGDS)

library work;
use work.WeightMatrix00.all;
use work.WeightMatrix01.all;
use work.Neuron_BramInLine;

entity NetWorkLevel00 is
     Port (
        -- Reset --
        Reset		: in std_logic;			-- Reset all elements of on this level - Don't Forget Matrix
		Resetok		: out std_logic := '0'; -- Reset it's Done - RESET Value '0'
		
		-- set machine --
		--CLK_ibufds  : in std_logic;			-- clock
		CLK         : in std_logic;			-- clock 
        Go  		: in std_logic;			-- start to compute
		Ready		: out std_logic := '0';	-- work is done - RESET Value '0'
		Latch		: in std_logic;			-- store results in a register
        MuR_outL0   : OUT std_logic_vector (0 to 5);                    -- largueur du bus de données muMachine

        -- Data Level Input-Output
	 	MatrixNumber: integer range 0 to (ML00STM_L-1) :=0; 
        Spike_I	    : IN std_logic_vector (ML01Y-1   downto 0);
	 	Spike_O		: out std_logic_vector ((ML00STM_X*ML00STM_Y)-1 downto 0)
    );
end NetWorkLevel00;

architecture NetWorkLevel00_Full of NetWorkLevel00 is
    -- horloges --
    --signal CLK        : std_logic;
        
    -- state Machine BRAM --
    signal addr       : integer range 0 to (ML00STM_L-1) := 0;    -- bus d'adresse (total 221 registres)

    signal MuRdata    : std_logic_vector (0 to 5):= (others => '0');                -- µMachine pour le reset et la comparaison
    
    -- state Machine --
    signal NmaC	      : integer range 0 to 6;       -- State mac   : 0 - one wait cycle after a reset
											        -- 		       : 1 - attendre 'go=0'
											        --			   : 2 - attendre 'go=1'
											        --			   : 4 - démarrage des processus enfants
											        --			   : 5 - attendre 'ready enfant' passe à 0
						 					        --		       : 6 - attendre 'ready enfant' passe à 1
	
    signal Lreset     : std_logic :='1';
    signal LGo        : std_logic :='0'; 
    signal LReady     : std_logic :='0';  
    signal LSpike_O   : std_logic_vector ((ML00STM_X*ML00STM_Y)-1 downto 0) := (others => '0');		
    				
 begin   
    -------------------------------------------------------------
	-- Clock system  - CONNECTION BETWEEN package CLOCK        --
	-------------------------------------------------------------  
    --clk1_in_bufg : BUFG
    --    port map (
    --      I => clk_ibufds,
    --      O => CLK
    --    );
	
    -------------------------------------------------------------
	-- connexion - previus level                               --
	-------------------------------------------------------------  
	

    -------------------------------------------------------------
	-- connexion - next level                                  --
	-------------------------------------------------------------  
    
	
    -------------------------------------------------------------
	-- Generate compute's cells                                --
	-------------------------------------------------------------  
	u1 : entity work.Neuron_BramInLine(Neuron_BramInLine_all) port map( 
                    CLK         => CLK,                         -- master clock
                    reset       => Lreset,                      -- demande d'initialisation
                    Go          => LGo,                         -- demande de réalisation du processus enfant
                    Ready       => LReady,                      -- fin de traitement du processus enfant
        
                    -- variables spécifiques --
                    BRaddr      => addr,    
                    BRdata_out  => LSpike_O,
                    BRMuR_out   => MuRdata
                    );
	
    ------------------------------------------------
	-- Processus State Machine - Compute          --
	------------------------------------------------  
    process(CLK, reset, NmaC)
    begin 
        if rising_edge(CLK) then
            -- processus mode RESET --
            if Reset='0' then
                addr <= 0;                  -- bus d'adresse (total 221 registres)
                NmaC <= 0;
				LGo <='0';
				Lreset <= '0';
				Resetok <='1';
				Ready <= '0';
	
                Spike_O <= (others =>'0');                        -- au reset le buffer doit être null
 
            -- processus mode state Machine SmacC --
            else
                case NmaC is
                    -- attendre que tous les processus enfants aient fini leur reset
                    when 0 =>
                        if (LReady = '1') then
                            Lreset <='1';
                            NmaC <= 1;
                        end if;
                    -- wait 1 cycle -- attendre un pusle sur go de 0 
                    when 1 =>
                        if (Go='0') then
                            NmaC <= 2;
                        end if;                    
                    -- wait 1 cycle -- attendre un pusle sur go à 1
                    when 2 =>
                        if (Go='1') then
                            NmaC <= 3;
                        end if;                    
                    -- démarrage des processus enfants --                        
                    when 3 =>
                        LGo <='1';
                        NmaC <= 4; 
                    -- attendre que le signal ready passe à 0 -> on sait que le processus enfnat à démarrer -> go = 0--
                    when 4 =>
                        if (LReady = '0') then
                            NmaC <= 5;
                            LGo <='0';
                        end if;
                   -- attendre que tous les processus enfants aient activer 'ready'
                    when 5 =>
                        if (LReady = '1') then
                           Ready <= '1';
                           NmaC <= 6;
                        end if;                            
                    -- wait 1 cycle --
                    when 6 =>
                        if (Latch = '1') then
                            Ready <= '0';
                            NmaC <= 0;
                            -- incrémenter l'adresse
                            addr <= addr + 1; 
                            -- faire les transfert de date --
                            Spike_O <= LSpike_O;
                            MuR_outL0<=  MuRdata;                    -- largueur du bus de données muMachine
                        end if;
                end case;
            end if;
        end if;
     end process;  
end NetWorkLevel00_Full;
