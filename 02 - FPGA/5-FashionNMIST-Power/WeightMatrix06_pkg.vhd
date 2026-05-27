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

package WeightMatrix06 is
	-- Taille de la matrice
    constant ML06X : natural := 1;
    constant ML06Y : natural := 10;

	-- Déclaration limite des variables
    constant ML06Minval : integer := -8192;    	-- Valeur minimale
    constant ML06Maxval : integer := +8191; 	-- Valeur maximale
    subtype ML06bounded_int is integer range ML06Minval to ML06Maxval;
 
    -- Déclaration de la matrice de poids
    type ML06int_array is array (0 to ML06Y-1) of ML06bounded_int;

 
 
end WeightMatrix06;
