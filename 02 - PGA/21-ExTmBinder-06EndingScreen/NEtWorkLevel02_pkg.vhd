-----------------------------------------------------------------------------
--
-- File : NetWorkLevel02.vhd
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
use work.WeightMatrix02.all;
use work.LInt_neuro;

package NetWorkLevel02_pkg is
   component NetWorkLevel02       
        Port (
            -- Reset --
            Reset		: in std_logic;			-- Reset all elements of on this level - Don't Forget Matrix
            Resetok		: out std_logic := '0'; -- Reset it's Done - RESET Value '0'
            
            -- set machine --
            CLK     	: in std_logic;			-- clock 
        
            Go  		: in std_logic;			-- start to compute
            Ready		: out std_logic := '0';	-- work is done - RESET Value '0'
            
            Latch		: in std_logic;			-- store results in a register
            MuR_inL2    : in std_logic_vector (0 to 5);                    -- largueur du bus de données muMachine
            MuR_outL2   : out std_logic_vector (0 to 5);                   -- largueur du bus de données muMachine
    
            -- Data Level Input-Output
            Spike_I		: IN std_logic_vector (ML02Y-1   downto 0);
            Spike_O		: OUT int_array_ML02 := (0,0,0,0,0,0,0,0,0,0)  --OUT integer range 0 to 9 := 0 
            );
    end component;
end NetWorkLevel02_pkg;

------------------------------------------------------------------
-- Definition des interconnexions -> NetWorkLevel01       		--
------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library unisim;  -- Ajoute la bibliothèque unisim
use unisim.vcomponents.all;  -- Importer tous les composants de unisim (dont IBUFGDS)

library work;
use work.WeightMatrix02.all;
use work.LInt_neuro;

entity NetWorkLevel02 is
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
        MuR_inL2    : in std_logic_vector (0 to 5);                    -- largueur du bus de données muMachine
        MuR_outL2   : out std_logic_vector (0 to 5);                   -- largueur du bus de données muMachine

        -- Data Level Input-Output
        Spike_I		: IN std_logic_vector (ML02Y-1   downto 0);
	 	Spike_O		: OUT int_array_ML02 := (0,0,0,0,0,0,0,0,0,0)  --OUT integer range 0 to 9 := 0 

    );
end NetWorkLevel02;

architecture NetWorkLevel02_Full of NetWorkLevel02 is
    -- horloges et gestion communication parent enfant --
    --signal CLK        : std_logic;
    
    -- state Machine --

    signal NmaC	      : integer range 0 to 6;       -- State mac   : 0 - one wait cycle after a reset
											        -- 		       : 1 - Mode Ready
											        --			   : 2 - Mode Start
											        --			   : 4 - Mode compute
											        --			   : 5 - one wait cycle
						 					        --		       : 6 - Mode Latch
											        --			   : 7 - one wait cycle
	    
    signal LMuR_inL2  : std_logic_vector (0 to 5);                    -- largueur du bus de données muMachine
    signal Lreset     : std_logic :='1';
    signal LGo        : std_logic :='0';
    signal LReady     : std_logic_vector ((ML02X-1) downto 0) := (others => '0');
    signal LSpike_I   : std_logic_vector (ML02Y-1 downto 0) := (others => '0');
    signal LSpike_O   : int_array_ML02 := (0,0,0,0,0,0,0,0,0,0); 

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
	u1 : for i in 0 to (ML02X-1) generate
	  LIntC_one : entity LInt_neuro port map( 
			CLK         => CLK,                         -- master clock
			reset       => Lreset,                      -- demande d'initialisation
            Go          => LGo,                         -- demande de réalisation du processus enfant
			Ready       => LReady(i),                   -- fin de traitement du processus enfant
            MuR_inL     => LMuR_inL2(0 to 1),                    -- transmission micro-machine

            -- variables spécifiques --
            NumberCell  => i,                           -- numéro de cellule 
			Spike_I     => Spike_I,                     -- imput spike pulses
            Spike_O 	=> LSpike_O(i)	                -- Output spike pulse
			);
	end generate u1;
	LSpike_I <= Spike_I;
   	LMuR_inL2 <= MuR_inL2;
	
    ------------------------------------------------
	-- Processus State Machine - Compute          --
	------------------------------------------------  
    process(CLK, reset, NmaC)
    begin 
        if rising_edge(CLK) then
            -- processus mode RESET --
            if Reset='0' then
				NmaC <= 0;
				LGo <='0';
				Lreset <= '0';
				Resetok <='1';
				Ready <= '0';
     
                Spike_O <= (others => 0);                            -- au reset le buffer doit être null
                
           -- processus mode state Machine SmacC --
            else
                case NmaC is
                    -- attendre que tous les processus enfants aient fini leur reset
                    when 0 =>
                        if (LReady = (LReady'range => '1')) then
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
                        if (LReady = (LReady'range => '0')) then
                            NmaC <= 5;
                            LGo <='0';
                         end if;
                   -- attendre que tous les processus enfants aient activer 'ready'
                    when 5 =>
                        if (LReady = (LReady'range => '1')) then
                           Ready <= '1';
                           NmaC <= 6;
                        end if;                            
                    -- wait 1 cycle --
                    when 6 =>
                        if (Latch = '1') then
                            Ready <= '0';
                            NmaC <= 0;

                            Spike_O <= LSpike_O;
                            MuR_outL2 <=MuR_inL2;
                         end if;
                 end case;
            end if;
        end if;
     end process;

end NetWorkLevel02_Full;
