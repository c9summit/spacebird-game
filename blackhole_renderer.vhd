library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity blackhole_renderer is
    port (
        clk          : in  std_logic;

        pixel_row    : in  std_logic_vector(9 downto 0);
        pixel_column : in  std_logic_vector(9 downto 0);

        bh_x         : in  integer range 0 to 639;
        bh_y         : in  integer range 0 to 479;

        red          : out std_logic_vector(3 downto 0);
        green        : out std_logic_vector(3 downto 0);
        blue         : out std_logic_vector(3 downto 0);

        active       : out std_logic
    );
end blackhole_renderer;

architecture behaviour of blackhole_renderer is

    constant BH_W : integer := 256;
    constant BH_H : integer := 128;

    component blackholeHD_rom is
    port (
        address : in  std_logic_vector(14 downto 0);
        clock   : in  std_logic;
        q       : out std_logic_vector(11 downto 0)
    );
    end component;

    signal rom_addr : std_logic_vector(14 downto 0);
    signal rom_data : std_logic_vector(11 downto 0);

begin

    bh_rom : blackholeHD_rom
    port map (
        clock   => clk,
        address => rom_addr,
        q       => rom_data
    );

    -- RENDER PROCESS
    process(pixel_row, pixel_column, rom_data, bh_x, bh_y)

        variable x : integer;
        variable y : integer;

        variable local_x : integer;
        variable local_y : integer;

        variable addr_int : integer;

    begin

        -- DEFAULT OUTPUTS
        red    <= "1111";
        green  <= "0000";
        blue   <= "0000";
        active <= '0';

        -- CURRENT SCREEN PIXEL
        x := to_integer(unsigned(pixel_column));
        y := to_integer(unsigned(pixel_row));

        -- CHECK IF CURRENT PIXEL INSIDE BLACKHOLE
        if (x >= bh_x and x < bh_x + BH_W and
            y >= bh_y and y < bh_y + BH_H) then

            -- LOCAL SPRITE COORDINATES
            local_x := x - bh_x;
            local_y := y - bh_y;

            -- CONVERT 2D -> ROM ADDRESS
            addr_int := local_y * BH_W + local_x;

            rom_addr <= std_logic_vector(
                to_unsigned(addr_int, 15)
            );

            if rom_data /= X"F6C" then

            red   <= rom_data(11 downto 8);
            green <= rom_data(7 downto 4);
            blue  <= rom_data(3 downto 0);
            active <= '1';

            else
                active <= '0';
        else

            rom_addr <= (others => '0');

        end if;

    end process;

end behaviour;