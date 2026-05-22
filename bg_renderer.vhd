library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bg_renderer is
    port (
        clk          : in  std_logic;
        pixel_row    : in  std_logic_vector(9 downto 0);
        pixel_column : in  std_logic_vector(9 downto 0);
        scroll_en    : in  std_logic;
        reset        : in  std_logic;
        red, green, blue : out std_logic_vector(3 downto 0)

    );
end bg_renderer;

architecture behaviour of bg_renderer is

    signal scroll_x : unsigned(9 downto 0) := (others => '0');

begin

    process(clk, reset)
    begin

        if reset = '1' then
            scroll_x <= (others => '0');

        elsif rising_edge(clk) then

            if scroll_en = '1' then
                scroll_x <= scroll_x + 1;
            end if;

        end if;

    end process;

    process(pixel_row, pixel_column, scroll_x)

    variable x  : integer;
    variable y  : integer;
    variable sx : integer;

begin

    x  := to_integer(unsigned(pixel_column));
    y  := to_integer(unsigned(pixel_row));
    sx := to_integer(scroll_x);

    -- Blue background
    red   <= "0000";
    green <= "0000";
    blue  <= "1111";

    -- White stars (4x4 pixels)
    if (((x + sx) mod 63 < 4) and
        ((y + sx) mod 47 < 4)) then

        red   <= "1111";
        green <= "1111";
        blue  <= "1111";

    end if;

    -- Yellow stars (3x3 pixels)
    if (((x + (sx/2)) mod 97 < 3) and
        (y mod 83 < 3)) then

        red   <= "1111";
        green <= "1111";
        blue  <= "0000";

    end if;

end process;

end behaviour;