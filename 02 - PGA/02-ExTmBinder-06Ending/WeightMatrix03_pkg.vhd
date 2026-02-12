----------------------------------------------------------------------
---
---  producted Package by julia - Weight matrix
---
----------------------------------------------------------------------
---
----------------------------------------------------
---
-- Pascal Harmeling 2025
---
----------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package WeightMatrix03 is
	-- Taille de la matrice
    constant ML03X : natural := 1;
    constant ML03Y : natural := 10;

	-- Déclaration limite des variables
    constant ML03Minval : integer := -1024;    	-- Valeur minimale
    constant ML03Maxval : integer := +1023; 	-- Valeur maximale
    subtype ML03bounded_int is integer range ML03Minval to ML03Maxval;
 
    -- Déclaration de la matrice de poids
    type ML03int_array is array (0 to ML03y-1) of ML03bounded_int;  -- avant -2000 to +2000

 
 
end WeightMatrix03;
