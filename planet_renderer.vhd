LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY planet_renderer IS
PORT(
    clk          : IN  STD_LOGIC;
    pixel_row    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
    pixel_column : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);

    planet_on    : OUT STD_LOGIC;
    red, green, blue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
);
END planet_renderer;

ARCHITECTURE behaviour OF planet_renderer IS

    -- ROM components
    COMPONENT jupiter_rom PORT(
        address : IN  STD_LOGIC_VECTOR(13 DOWNTO 0);
        clock   : IN  STD_LOGIC;
        q       : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
    ); END COMPONENT;

    COMPONENT saturn_rom PORT(
        address : IN  STD_LOGIC_VECTOR(13 DOWNTO 0);
        clock   : IN  STD_LOGIC;
        q       : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
    ); END COMPONENT;

    COMPONENT uranus_rom PORT(
        address : IN  STD_LOGIC_VECTOR(13 DOWNTO 0);
        clock   : IN  STD_LOGIC;
        q       : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
    ); END COMPONENT;

    COMPONENT neptune_rom PORT(
        address : IN  STD_LOGIC_VECTOR(13 DOWNTO 0);
        clock   : IN  STD_LOGIC;
        q       : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
    ); END COMPONENT;

    -- Screen positions (4 quadrants)
    CONSTANT SIZE : INTEGER := 96;

    CONSTANT JUP_X : INTEGER := 80;
    CONSTANT JUP_Y : INTEGER := 60;

    CONSTANT SAT_X : INTEGER := 420;
    CONSTANT SAT_Y : INTEGER := 60;

    CONSTANT URA_X : INTEGER := 80;
    CONSTANT URA_Y : INTEGER := 300;

    CONSTANT NEP_X : INTEGER := 420;
    CONSTANT NEP_Y : INTEGER := 300;

    SIGNAL pr, pc : INTEGER;

    -- relative coords
    SIGNAL jx, jy, jaddr : INTEGER;
    SIGNAL sx, sy, saddr : INTEGER;
    SIGNAL ux, uy, uaddr : INTEGER;
    SIGNAL nx, ny, naddr : INTEGER;

    -- ROM outputs
    SIGNAL jup_pix, sat_pix, ura_pix, nep_pix : STD_LOGIC_VECTOR(11 DOWNTO 0);

    -- hit flags
    SIGNAL in_jup, in_sat, in_ura, in_nep : STD_LOGIC;

BEGIN

    --------------------------------------------------------------------
    -- coordinate conversion
    --------------------------------------------------------------------
    pr <= CONV_INTEGER(UNSIGNED(pixel_row));
    pc <= CONV_INTEGER(UNSIGNED(pixel_column));

    --------------------------------------------------------------------
    -- region detection (quadrants)
    --------------------------------------------------------------------
    in_jup <= '1' WHEN (pc >= JUP_X AND pc < JUP_X + SIZE AND
                        pr >= JUP_Y AND pr < JUP_Y + SIZE)
              ELSE '0';

    in_sat <= '1' WHEN (pc >= SAT_X AND pc < SAT_X + SIZE AND
                        pr >= SAT_Y AND pr < SAT_Y + SIZE)
              ELSE '0';

    in_ura <= '1' WHEN (pc >= URA_X AND pc < URA_X + SIZE AND
                        pr >= URA_Y AND pr < URA_Y + SIZE)
              ELSE '0';

    in_nep <= '1' WHEN (pc >= NEP_X AND pc < NEP_X + SIZE AND
                        pr >= NEP_Y AND pr < NEP_Y + SIZE)
              ELSE '0';

    --------------------------------------------------------------------
    -- address generation
    --------------------------------------------------------------------
    jx <= pc - JUP_X;
    jy <= pr - JUP_Y;
    jaddr <= (jy * SIZE) + jx;

    sx <= pc - SAT_X;
    sy <= pr - SAT_Y;
    saddr <= (sy * SIZE) + sx;

    ux <= pc - URA_X;
    uy <= pr - URA_Y;
    uaddr <= (uy * SIZE) + ux;

    nx <= pc - NEP_X;
    ny <= pr - NEP_Y;
    naddr <= (ny * SIZE) + nx;

    --------------------------------------------------------------------
    -- ROM instantiations
    --------------------------------------------------------------------
    JUP_ROM : jupiter_rom PORT MAP(
        address => CONV_STD_LOGIC_VECTOR(jaddr, 14),
        clock   => clk,
        q       => jup_pix
    );

    SAT_ROM : saturn_rom PORT MAP(
        address => CONV_STD_LOGIC_VECTOR(saddr, 14),
        clock   => clk,
        q       => sat_pix
    );

    URA_ROM : uranus_rom PORT MAP(
        address => CONV_STD_LOGIC_VECTOR(uaddr, 14),
        clock   => clk,
        q       => ura_pix
    );

    NEP_ROM : neptune_rom PORT MAP(
        address => CONV_STD_LOGIC_VECTOR(naddr, 14),
        clock   => clk,
        q       => nep_pix
    );

    --------------------------------------------------------------------
    -- RGB output mux (priority-based)
    --------------------------------------------------------------------
    PROCESS(in_jup, in_sat, in_ura, in_nep,
            jup_pix, sat_pix, ura_pix, nep_pix)
    BEGIN

        planet_on <= '0';

        red   <= "0000";
        green <= "0000";
        blue  <= "0000";

        -- priority: Jupiter → Saturn → Uranus → Neptune

        IF in_jup = '1' THEN
            red   <= jup_pix(11 DOWNTO 8);
            green <= jup_pix(7 DOWNTO 4);
            blue  <= jup_pix(3 DOWNTO 0);
            planet_on <= '1';

        ELSIF in_sat = '1' THEN
            red   <= sat_pix(11 DOWNTO 8);
            green <= sat_pix(7 DOWNTO 4);
            blue  <= sat_pix(3 DOWNTO 0);
            planet_on <= '1';

        ELSIF in_ura = '1' THEN
            red   <= ura_pix(11 DOWNTO 8);
            green <= ura_pix(7 DOWNTO 4);
            blue  <= ura_pix(3 DOWNTO 0);
            planet_on <= '1';

        ELSIF in_nep = '1' THEN
            red   <= nep_pix(11 DOWNTO 8);
            green <= nep_pix(7 DOWNTO 4);
            blue  <= nep_pix(3 DOWNTO 0);
            planet_on <= '1';

        END IF;

    END PROCESS;

END behaviour;