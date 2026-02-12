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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package WeightMatrix00 is

	-- Taille de la matrice
	constant ML00STM_X  : natural := 28;  	-- chaque image x = 28 pixels.
	constant ML00STM_Y  : natural := 28;  	-- chaque image y = 28 pixels -> x*y donne un vecteur de 784 bits.
	constant ML00STM_L  : natural := 110000;-- il y a 500 séquence de chiffres composées chaqune de 220 images.


end WeightMatrix00;
