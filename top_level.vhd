LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY top_level is
    port(
        clock_25MHz, reset : IN std_logic;
        red_out, green_out, blue_out : OUT std_logic_vector(3 downto 0);
        hsync, vsync : OUT std_logic
    );

end top_level;

architecture rtl of top_levl is 
    SIGNAl pixel_row, pixel_column : STD_LOGIC_VECTOR(9 downto 0);
    SIGNAL r_vga, g_vga, b_vga : STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL bg_r, bg_g, bg_b : STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL pipe_on  : STD_LOGIC;
    SIGNAL pipe_r, pipe_g, pipe_b   : STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL pipe_x, gap_top, gap_bot   : STD_LOGIC_VECTOR(9 DOWNTO 0);

    SIGNAL hsync_i, vsync_i : STD_LOGIC;
    SIGNAL scroll_en : STD_LOGIC := '1';

begin
    vga_unit : ENTITY work.VGA_SYNC
    PORT MAP(
        clock_25Mhz     => clock_25Mhz,

        red             => r_vga,
        green           => g_vga,
        blue            => b_vga,

        red_out         => red_out,
        green_out       => green_out,
        blue_out        => blue_out,

        horiz_sync_out  => hsync,
        vert_sync_out   => vsync,

        pixel_row       => pixel_row,
        pixel_column    => pixel_column
    );

    bg_unit : ENTITY work.bg_test
    PORT MAP(
        clk          => clock_25Mhz,
        pixel_row    => pixel_row,
        pixel_column => pixel_column,
        scroll_en    => scroll_en,

        red          => bg_r,
        green        => bg_g,
        blue         => bg_b
    );


    pipe_unit : ENTITY work.pipes_game
    PORT MAP(
        clk           => clock_25Mhz,
        vert_sync     => vsync,       
        scroll_en     => scroll_en,
        training_mode => '1',
        score_rst     => reset,

        pixel_row     => pixel_row,
        pixel_column  => pixel_column,

        pipe_on       => pipe_on,
        pipe_red      => pipe_r,
        pipe_green    => pipe_g,
        pipe_blue     => pipe_b,

        pipe_x_out    => pipe_x,
        gap_top_out   => gap_top,
        gap_bot_out   => gap_bot
    );

    PROCESS(bg_r, bg_g, bg_b, pipe_r, pipe_g, pipe_b, pipe_on)
    BEGIN

        IF pipe_on = '1' THEN
            r_vga <= pipe_r;
            g_vga <= pipe_g;
            b_vga <= pipe_b;

        ELSE
            r_vga <= bg_r;
            g_vga <= bg_g;
            b_vga <= bg_b;

        END IF;

    END PROCESS;

END rtl;