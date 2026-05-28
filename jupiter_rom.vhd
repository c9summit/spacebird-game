LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;
LIBRARY altera_mf;
USE altera_mf.all;

ENTITY jupiter_rom IS
PORT(
	address : IN  STD_LOGIC_VECTOR(13 DOWNTO 0);
	clock   : IN  STD_LOGIC;
	q       : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
);
END jupiter_rom;

ARCHITECTURE SYN OF jupiter_rom IS

COMPONENT altsyncram
GENERIC (
	address_aclr_a        : STRING;
	clock_enable_input_a  : STRING;
	clock_enable_output_a : STRING;
	init_file             : STRING;
	intended_device_family: STRING;
	lpm_hint              : STRING;
	lpm_type              : STRING;
	numwords_a            : NATURAL;
	operation_mode        : STRING;
	outdata_aclr_a        : STRING;
	outdata_reg_a         : STRING;
	widthad_a             : NATURAL;
	width_a               : NATURAL;
	width_byteena_a       : NATURAL
);
PORT (
	clock0    : IN  STD_LOGIC;
	address_a : IN  STD_LOGIC_VECTOR(13 DOWNTO 0);
	q_a       : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
);
END COMPONENT;

BEGIN

altsyncram_component : altsyncram
GENERIC MAP (
	address_aclr_a        => "NONE",
	clock_enable_input_a  => "BYPASS",
	clock_enable_output_a => "BYPASS",
	init_file             => "jupiter.mif",
	intended_device_family=> "Cyclone V",
	lpm_hint              => "ENABLE_RUNTIME_MOD=NO",
	lpm_type              => "altsyncram",
	numwords_a            => 9216,
	operation_mode        => "ROM",
	outdata_aclr_a        => "NONE",
	outdata_reg_a         => "UNREGISTERED",
	widthad_a             => 14,
	width_a               => 12,
	width_byteena_a       => 1
)
PORT MAP (
	clock0    => clock,
	address_a => address,
	q_a       => q
);

END SYN;