LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY seven_seg IS
	PORT(input : IN std_logic_vector(2 DOWNTO 0);
		output : OUT std_logic_vector(6 DOWNTO 0) );
END seven_seg;

ARCHITECTURE behaviour OF seven_seg IS
	BEGIN
		WITH input SELECT
			output <= 
			"1000000" WHEN "000",  -- 0
			"1111001" WHEN "001",  -- 1
			"0100100" WHEN "010",  -- 2
			"0110000" WHEN "011",  -- 3
			"0011001" WHEN "100",  -- 4
			"0010010" WHEN "101",  -- 5
			"1111111" WHEN OTHERS; 
END behaviour;