-----------------------------------------------------------------------------
--
-- File : Hub75_pkg.vhd
--
-- Description : VHDL source code for PLD or FPGA - Matrix led RGB driver
--
-- Chip : Unknow - devel.
--
-- Creation Date : april 06th, 2025
--
-- Last Modification Date : april 06th, 2025
--
-- Last Modified by : Pascal Harmeling
--
-- update : start integration Matrix led RGB
-- Update : 
-- Update : 
	
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
use work.BackGroundDisplay.all;
use work.WeightMatrix00.all;
use work.MyNumber.all;

package Hub75Tm_pkg is
    component Hub75Tm
        generic(
            WIDTH       : integer := 64;
            HEIGHT      : integer := 32;
            SCAN_LINES  : integer := 16      
        );        
        Port (
            CLK_50MHZ	: IN std_logic; 		-- Master clock Positive @ 200 MHz
            
            hub75_R1    : OUT std_logic;        -- led color RED - line 1
            hub75_G1    : OUT std_logic;        -- led color RED - line 1
            hub75_B1    : OUT std_logic;        -- led color RED - line 1
            
            hub75_R2    : OUT std_logic;        -- led color RED - line 2
            hub75_G2    : OUT std_logic;        -- led color RED - line 2
            hub75_B2    : OUT std_logic;        -- led color RED - line 2
            
            hub75_A     : OUT std_logic;        -- Select line MUX ADD A
            hub75_B     : OUT std_logic;        -- Select line MUX ADD B
            hub75_C     : OUT std_logic;        -- Select line MUX ADD C
            hub75_D     : OUT std_logic;        -- Select line MUX ADD D
            hub75_E     : OUT std_logic;        -- Select line MUX ADD E
            
            hub75_CLK   : OUT std_logic;        -- Clock write led value
            hub75_LAT   : OUT std_logic;        -- Store all led value
            hub75_OE    : OUT std_logic;        -- Output Enable led Matrix 
            
            Resetok     : OUT std_logic;        -- Graphic display ready
            
            Displm      : IN std_logic_vector ((ML00STM_X*ML00STM_Y)-1 downto 0);     -- la matrice inline          
            DisplRv     : IN integer range 0 to 9;       -- Define number value - display
            switchSoR   : IN std_logic                   -- switch between matrix spike trace OR number value - display
        );
        end component;
end Hub75Tm_pkg;

------------------------------------------------------------------
-- Definition des interconnexions -> Hub75               		--
------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.BackGroundDisplay.all;
use work.WeightMatrix00.all;
use work.MyNumber.all;

entity Hub75Tm is
    generic(
        WIDTH       : integer := 64;
        HEIGHT      : integer := 32;
        SCAN_LINES  : integer := 16
        );
    
    Port (
        CLK_50MHZ	: IN std_logic; 		-- Master clock Positive @ 200 MHz

        hub75_R1    : OUT std_logic;        -- led color RED - line 1
        hub75_G1    : OUT std_logic;        -- led color RED - line 1
        hub75_B1    : OUT std_logic;        -- led color RED - line 1
        
        hub75_R2    : OUT std_logic;        -- led color RED - line 2
        hub75_G2    : OUT std_logic;        -- led color RED - line 2
        hub75_B2    : OUT std_logic;        -- led color RED - line 2
        
        hub75_A     : OUT std_logic;        -- Select line MUX ADD A
        hub75_B     : OUT std_logic;        -- Select line MUX ADD B
        hub75_C     : OUT std_logic;        -- Select line MUX ADD C
        hub75_D     : OUT std_logic;        -- Select line MUX ADD D
        hub75_E     : OUT std_logic;        -- Select line MUX ADD E
        
        hub75_CLK   : OUT std_logic;        -- Clock write led value
        hub75_LAT   : OUT std_logic;        -- Store all led value
        hub75_OE    : OUT std_logic;        -- Output Enable led Matrix 
        
        Resetok     : OUT std_logic;        -- Graphic display ready
        
        Displm      : IN std_logic_vector ((ML00STM_X*ML00STM_Y)-1 downto 0);     -- la matrice inline          
        DisplRv     : IN integer range 0 to 9;       -- Define number value - display
        switchSoR   : IN std_logic                   -- switch between matrix spike trace (0) OR number value (1) - display
);
end Hub75Tm;

architecture Hub75Tm_Full of Hub75Tm is
    -- horloges --
    signal clk_div    : integer range 0 to 100 := 0;
    signal pix_clk    : std_logic := '0';

    -- gestion affichage --
    signal reset      : std_logic :='0';
    signal row        : integer range 0 to SCAN_LINES-1 := 0;
    signal col        : integer range 0 to WIDTH-1 := 0;
    signal CounterClk : integer range 0 to (WIDTH*4) := 0;
 
    -- gestion de mise à jour affichage -- 
    signal reload     : std_logic :='0';                  -- préparation de mise à jour display -> reset local -- 
    signal UpdateDis  : integer range 0 to 3 :=0;         -- période de mise à jour du display
    signal y          : integer range 0 to HEIGHT-1 := 0;
    signal x          : integer range 0 to WIDTH-1 := 0;
 
    -- mémoire réservée pour l'affichage et le background --
    -- background display --
    signal test_frame : framebuffer_BGD;
    
    -- Spiking trace --
    signal DDisplRv     : integer range 0 to 9;       -- Define number value - display
    -- Number display --
    signal MyNumber    : framebuffer_MyN := CMyNumber;
    
 begin              
    -------------------------------------------------------------
	-- Horloge system                                          --
	-------------------------------------------------------------  
    process(CLK_50MHZ)
    begin                    
       if rising_edge(CLK_50MHZ) then
            if clk_div = 9 then
                clk_div <= 0;
                pix_clk <= not(pix_clk);
            else
                clk_div <= clk_div + 1;
            end if;
        end if;
    end process;

    ------------------------------------------------
	-- Affichage  RESET - MISE A JOUR - AFFICHAGE --
	------------------------------------------------  
    process(CLK_50MHZ, reset, reload, UpdateDis)
    variable rowY : integer range 0 to 783;
    begin 
     if rising_edge(CLK_50MHZ) then
        -- processus mode RESET --
        if reset='0' then
            test_frame(y, x) <= get_BGDpixel(BgM1, y, x); --(HEIGHT-1), 0 to (WIDTH-1)
            if (x<(WIDTH-1)) then                  
                x<=x+1;
            else
                x<=0;
                if (y<(HEIGHT-1)) then
                    y<=y+1; 
                else
                    DDisplRv <= 0;
                    reset <='1';
                    Resetok <='1';
                end if;
            end if;
        else
            -- copie de la ligne en cours d'affichage -- reset local -> préparation pointeurs
            -- Spécial pour le Spiking Trace --
            if reload='1' then
                DDisplRv <= DisplRv;
                x<=0;
                y<=0;
            else
                if (UpdateDis = 1) and (row<14) then
                      rowY := row*ML00STM_Y;
                      if Displm(rowY+x)='1' then
                            test_frame(row+2, x+34) <= "111";
                      else  
                            test_frame(row+2, x+34) <= "000" ;
                      end if;
                      if Displm(rowY+392+x)='1' then
                            test_frame(row+16, x+34) <= "111";
                      else  
                            test_frame(row+16, x+34) <= "000" ;
                      end if;
                      if x< (ML00STM_X-1) then
                            x<= x+1;
                      end if; 

                      if MyNumber(DDisplRv, row, x)='1' then
                            test_frame(row+2, x+2) <= "001";
                      else  
                            test_frame(row+2, x+2) <= "000" ;
                      end if;
                      if MyNumber(DDisplRv, row+14, x)='1' then
                            test_frame(row+16, x+2) <= "001";
                      else  
                            test_frame(row+16, x+2) <= "000" ;
                      end if;
                      if x< (ML00STM_X-1) then
                            x<= x+1;
                      end if; 
                end if;
            end if; 
         end if;
     end if;
     end process;
     
    -----------------------------------------
	-- Affichage  processus continu        --
	-----------------------------------------  
	hub75_CLK <= pix_clk when (CounterClk<(WIDTH+2)) else '0';

    process(pix_clk, CounterClk, reset, reload, UpdateDis)
    begin
     if rising_edge(pix_clk) then
        -- processus mode RESET --
        if reset='1' then
            case CounterClk is  
                -- chargement de la ligne de pixel dans leregistre DEC de la matrice LED --       
                when 0 to (WIDTH-1) =>
                    reload <= '0';
                    UpdateDis <= 0;   
                    col <= CounterClk;
                    hub75_OE  <= '1';
                    hub75_LAT <= '0';
                -- pause avant chargement de l'affichgage dans le buffer --
                when WIDTH =>
                    reload <= '0';
                    UpdateDis <= 0;   
                    col <= 0;
                    hub75_OE  <= '1';
                    hub75_LAT <= '0';
                -- chargement de l'affichgage dans le buffer --    
                when WIDTH+1 =>
                    reload <= '1';
                    UpdateDis <= 0;   
                    col <= 0; 
                    hub75_OE  <= '1';
                    hub75_LAT <= '1';
                -- affichage + premiere période de mise à jour de la mémoire d'affichage -- durée -> WIDTH
                when (WIDTH+2) to (WIDTH*2+1)=>
                    reload <= '0';
                    UpdateDis <= 1;   
                    col <= 0;
                    hub75_OE  <= '1';
                    hub75_LAT <= '0';
                -- affichage + seconde période de mise à jour de la mémoire d'affichage --  durée -> WIDTH  
                when (WIDTH*2+2) to (WIDTH*3+1)=>
                    reload <= '0';
                    UpdateDis <= 2;   
                    col <= 0;
                    hub75_OE  <= '0';
                    hub75_LAT <= '0';
                -- affichage + troisième période de mise à jour de la mémoire d'affichage --  ! durée -> WIDTH-2 !      
                when (WIDTH*3+2) to (WIDTH*4-1)=>
                    reload <= '0';
                    UpdateDis <= 3;   
                    col <= 0;
                    hub75_OE  <= '0';
                    hub75_LAT <= '0';
                -- fin affichage de la ligne -- 
                when (WIDTH*4) =>
                    reload <= '0';
                    UpdateDis <= 0;
                    col <= 0;
                    hub75_OE  <= '1';
                    hub75_LAT <= '0';    
            end case;
    
            if CounterClk<(WIDTH*4) then
                CounterClk <= CounterClk+1;
            else
                CounterClk <= 0;            
                if  UpdateDis<3 then    
                     UpdateDis <=  UpdateDis +1;
                else
                     UpdateDis <= 0;
                end if;
                
                if (row <(SCAN_LINES-1)) then
                    row <= row +1;
                else
                    row <= 0;
              end if;
            end if;
               
            hub75_A <= std_logic(to_unsigned(row, 4)(0));
            hub75_B <= std_logic(to_unsigned(row, 4)(1));
            hub75_C <= std_logic(to_unsigned(row, 4)(2));
            hub75_D <= std_logic(to_unsigned(row, 4)(3));
            hub75_E <= '0';
            
            -- les 64 premier clock -> shift registrer)
            hub75_R1 <= test_frame(row,col)(2); --test_frame(row,col)(2);
            hub75_G1 <= test_frame(row,col)(1);
            hub75_B1 <= test_frame(row,col)(0);
            
            hub75_R2 <= test_frame(row + SCAN_LINES,col)(2);
            hub75_G2 <= test_frame(row + SCAN_LINES,col)(1);
            hub75_B2 <= test_frame(row + SCAN_LINES,col)(0);
            
          end if;
    end if;     
    end process;
end Hub75Tm_Full;
