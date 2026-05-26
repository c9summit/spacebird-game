library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bg_renderer is
port (
    clk          : in  std_logic;
    pixel_row    : in  std_logic_vector(9 downto 0);
    pixel_column : in  std_logic_vector(9 downto 0);
    scroll_en    : in  std_logic;
    red, green, blue : out std_logic_vector(3 downto 0)
);
end bg_renderer;

architecture behaviour of bg_renderer is

    -- -------------------------------------------------------
    -- ROM Components
    -- -------------------------------------------------------
    component blackholeHD_rom is
    port (
        address : in  std_logic_vector(14 downto 0);
        clock   : in  std_logic;
        q       : out std_logic_vector(11 downto 0)
    );
    end component;

    component jupiter_rom is
    port (
        address : in  std_logic_vector(13 downto 0);
        clock   : in  std_logic;
        q       : out std_logic_vector(11 downto 0)
    );
    end component;

    component uranus_rom is
    port (
        address : in  std_logic_vector(13 downto 0);
        clock   : in  std_logic;
        q       : out std_logic_vector(11 downto 0)
    );
    end component;

    component saturn_rom is
    port (
        address : in  std_logic_vector(13 downto 0);
        clock   : in  std_logic;
        q       : out std_logic_vector(11 downto 0)
    );
    end component;

    component neptune_rom is
    port (
        address : in  std_logic_vector(13 downto 0);
        clock   : in  std_logic;
        q       : out std_logic_vector(11 downto 0)
    );
    end component;

    -- -------------------------------------------------------
    -- Image dimensions
    -- -------------------------------------------------------
    constant BH_W  : integer := 256;
    constant BH_H  : integer := 128;
    constant PLT_W : integer := 128;
    constant PLT_H : integer := 72;

    -- Planet screen positions (top-left corner of each planet)
    constant JUP_X : integer := 50;
    constant JUP_Y : integer := 50;
    constant URA_X : integer := 350;
    constant URA_Y : integer := 30;
    constant SAT_X : integer := 80;
    constant SAT_Y : integer := 280;
    constant NEP_X : integer := 380;
    constant NEP_Y : integer := 260;
    constant BH_X  : integer := 200;
    constant BH_Y  : integer := 160;

    -- -------------------------------------------------------
    -- ROM signals
    -- -------------------------------------------------------
    signal bh_addr  : std_logic_vector(14 downto 0);
    signal bh_data  : std_logic_vector(11 downto 0);

    signal jup_addr : std_logic_vector(13 downto 0);
    signal jup_data : std_logic_vector(11 downto 0);

    signal ura_addr : std_logic_vector(13 downto 0);
    signal ura_data : std_logic_vector(11 downto 0);

    signal sat_addr : std_logic_vector(13 downto 0);
    signal sat_data : std_logic_vector(11 downto 0);

    signal nep_addr : std_logic_vector(13 downto 0);
    signal nep_data : std_logic_vector(11 downto 0);

    -- Scrolling
    signal scroll_x : unsigned(9 downto 0) := (others => '0');

    -- Star signals
    signal star_white  : std_logic;
    signal star_yellow : std_logic;

begin

    -- -------------------------------------------------------
    -- ROM Instantiations
    -- -------------------------------------------------------
    bh_rom : blackholeHD_rom
    port map (
        clock   => clk,
        address => bh_addr,
        q       => bh_data
    );

    jup_rom : jupiter_rom
    port map (
        clock   => clk,
        address => jup_addr,
        q       => jup_data
    );

    ura_rom : uranus_rom
    port map (
        clock   => clk,
        address => ura_addr,
        q       => ura_data
    );

    sat_rom : saturn_rom
    port map (
        clock   => clk,
        address => sat_addr,
        q       => sat_data
    );

    nep_rom : neptune_rom
    port map (
        clock   => clk,
        address => nep_addr,
        q       => nep_data
    );

    -- -------------------------------------------------------
    -- Scroll counter
    -- -------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if scroll_en = '1' then
                scroll_x <= scroll_x + 1;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------
    -- ROM address calculation
    -- -------------------------------------------------------
    process(pixel_row, pixel_column, scroll_x)
        variable x     : integer;
        variable y     : integer;
        variable sx    : integer;
        variable bh_x  : integer;
        variable bh_y  : integer;
        variable jup_x : integer;
        variable jup_y : integer;
        variable ura_x : integer;
        variable ura_y : integer;
        variable sat_x : integer;
        variable sat_y : integer;
        variable nep_x : integer;
        variable nep_y : integer;
    begin
        x  := to_integer(unsigned(pixel_column));
        y  := to_integer(unsigned(pixel_row));
        sx := to_integer(scroll_x);

        -- blackhole: centred at BH_X, BH_Y, clamp within image bounds
        bh_x := x - BH_X;
        bh_y := y - BH_Y;
        if bh_x < 0 then bh_x := 0; end if;
        if bh_y < 0 then bh_y := 0; end if;
        if bh_x >= BH_W then bh_x := BH_W - 1; end if;
        if bh_y >= BH_H then bh_y := BH_H - 1; end if;
        bh_addr <= std_logic_vector(to_unsigned(bh_y * BH_W + bh_x, 15));

        -- Jupiter
        jup_x := x - JUP_X;
        jup_y := y - JUP_Y;
        if jup_x < 0 then jup_x := 0; end if;
        if jup_y < 0 then jup_y := 0; end if;
        if jup_x >= PLT_W then jup_x := PLT_W - 1; end if;
        if jup_y >= PLT_H then jup_y := PLT_H - 1; end if;
        jup_addr <= std_logic_vector(to_unsigned(jup_y * PLT_W + jup_x, 14));

        -- Uranus
        ura_x := x - URA_X;
        ura_y := y - URA_Y;
        if ura_x < 0 then ura_x := 0; end if;
        if ura_y < 0 then ura_y := 0; end if;
        if ura_x >= PLT_W then ura_x := PLT_W - 1; end if;
        if ura_y >= PLT_H then ura_y := PLT_H - 1; end if;
        ura_addr <= std_logic_vector(to_unsigned(ura_y * PLT_W + ura_x, 14));

        -- Saturn
        sat_x := x - SAT_X;
        sat_y := y - SAT_Y;
        if sat_x < 0 then sat_x := 0; end if;
        if sat_y < 0 then sat_y := 0; end if;
        if sat_x >= PLT_W then sat_x := PLT_W - 1; end if;
        if sat_y >= PLT_H then sat_y := PLT_H - 1; end if;
        sat_addr <= std_logic_vector(to_unsigned(sat_y * PLT_W + sat_x, 14));

        -- Neptune
        nep_x := x - NEP_X;
        nep_y := y - NEP_Y;
        if nep_x < 0 then nep_x := 0; end if;
        if nep_y < 0 then nep_y := 0; end if;
        if nep_x >= PLT_W then nep_x := PLT_W - 1; end if;
        if nep_y >= PLT_H then nep_y := PLT_H - 1; end if;
        nep_addr <= std_logic_vector(to_unsigned(nep_y * PLT_W + nep_x, 14));

    end process;

    -- -------------------------------------------------------
    -- Star pattern (combinational, same as your original)
    -- -------------------------------------------------------
    process(pixel_row, pixel_column, scroll_x)
        variable x  : integer;
        variable y  : integer;
        variable sx : integer;
    begin
        x  := to_integer(unsigned(pixel_column));
        y  := to_integer(unsigned(pixel_row));
        sx := to_integer(scroll_x);

        star_white  <= '0';
        star_yellow <= '0';

        if (((x + sx) mod 63 < 4) and ((y + sx) mod 47 < 4)) then
            star_white <= '1';
        end if;
        if (((x + (sx/2)) mod 97 < 3) and (y mod 83 < 3)) then
            star_yellow <= '1';
        end if;
    end process;

    -- -------------------------------------------------------
    -- Layer compositor
    -- Priority (top to bottom):
    --   1. Planets (jupiter, uranus, saturn, neptune)
    --   2. Blackhole
    --   3. Stars (white then yellow)
    --   4. Black background
    --
    -- A ROM pixel is transparent if it is pure black (000)
    -- -------------------------------------------------------
    process(pixel_row, pixel_column,
            bh_data, jup_data, ura_data, sat_data, nep_data,
            star_white, star_yellow, scroll_x)
        variable x : integer;
        variable y : integer;
        variable r : std_logic_vector(3 downto 0);
        variable g : std_logic_vector(3 downto 0);
        variable b : std_logic_vector(3 downto 0);
    begin
        x := to_integer(unsigned(pixel_column));
        y := to_integer(unsigned(pixel_row));

        -- Layer 4: black background
        r := "0000"; g := "0000"; b := "0000";

        -- Layer 3: stars
        if star_white = '1' then
            r := "1111"; g := "1111"; b := "1111";
        end if;
        if star_yellow = '1' then
            r := "1111"; g := "1111"; b := "0000";
        end if;

        -- Layer 2: blackhole (only within its bounds, skip if pixel is black)
        if (x >= BH_X and x < BH_X + BH_W and
            y >= BH_Y and y < BH_Y + BH_H) then
            if bh_data /= "000000000000" then
                r := bh_data(11 downto 8);
                g := bh_data(7  downto 4);
                b := bh_data(3  downto 0);
            end if;
        end if;

        -- Layer 1: planets (skip if pixel is black = transparent)
        if (x >= JUP_X and x < JUP_X + PLT_W and
            y >= JUP_Y and y < JUP_Y + PLT_H) then
            if jup_data /= "000000000000" then
                r := jup_data(11 downto 8);
                g := jup_data(7  downto 4);
                b := jup_data(3  downto 0);
            end if;
        end if;

        if (x >= URA_X and x < URA_X + PLT_W and
            y >= URA_Y and y < URA_Y + PLT_H) then
            if ura_data /= "000000000000" then
                r := ura_data(11 downto 8);
                g := ura_data(7  downto 4);
                b := ura_data(3  downto 0);
            end if;
        end if;

        if (x >= SAT_X and x < SAT_X + PLT_W and
            y >= SAT_Y and y < SAT_Y + PLT_H) then
            if sat_data /= "000000000000" then
                r := sat_data(11 downto 8);
                g := sat_data(7  downto 4);
                b := sat_data(3  downto 0);
            end if;
        end if;

        if (x >= NEP_X and x < NEP_X + PLT_W and
            y >= NEP_Y and y < NEP_Y + PLT_H) then
            if nep_data /= "000000000000" then
                r := nep_data(11 downto 8);
                g := nep_data(7  downto 4);
                b := nep_data(3  downto 0);
            end if;
        end if;

        red   <= r;
        green <= g;
        blue  <= b;
    end process;

end behaviour;