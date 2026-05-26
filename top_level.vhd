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

architecture rtl of top_level is 
    COMPONENT VGA_SYNC IS
	PORT(	clock_25Mhz : IN STD_LOGIC; 
		   red, green, blue : IN STD_LOGIC_VECTOR(3 downto 0);
			red_out, green_out, blue_out : OUT STD_LOGIC_VECTOR(3 downto 0);
			horiz_sync_out, vert_sync_out	: OUT	STD_LOGIC;
			pixel_row, pixel_column: OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
    END VGA_SYNC;

    COMPONENT bg_renderer is
    port (
        clk          : in  std_logic;
        pixel_row    : in  std_logic_vector(9 downto 0);
        pixel_column : in  std_logic_vector(9 downto 0);
        scroll_en    : in  std_logic;
        red, green, blue : out std_logic_vector(3 downto 0));
    end bg_renderer;

    COMPONENT pipes_game IS
    PORT(
        clk           : IN  STD_LOGIC;
        vert_sync     : IN  STD_LOGIC;
        scroll_en     : IN  STD_LOGIC;
        training_mode : IN  STD_LOGIC;
        score_rst     : IN  STD_LOGIC;

        pixel_row     : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column  : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);

        pipe_on       : OUT STD_LOGIC;
        pipe_red      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        pipe_green    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        pipe_blue     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);

        pipe_x_out    : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        gap_top_out   : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        gap_bot_out   : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
    );
    END pipes_game;

    COMPONENT falling IS
    PORT(lmsb, clk, vert_sync : IN STD_LOGIC;
        pixel_row, pixel_column : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        red, green, blue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
    END falling;

    SIGNAl pixel_row, pixel_column : STD_LOGIC_VECTOR(9 downto 0);
    SIGNAL r_vga, g_vga, b_vga : STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL bg_r, bg_g, bg_b : STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL pipe_on  : STD_LOGIC;
    SIGNAL pipe_r, pipe_g, pipe_b   : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL pipe_x, gap_top, gap_bot   : STD_LOGIC_VECTOR(9 DOWNTO 0);

    SIGNAL rocket_r, rocket_g, rocket_b : STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL hsync_i, vsync_i : STD_LOGIC;
    SIGNAL scroll_en : STD_LOGIC := '1';

begin

    vga_unit : VGA_SYNC
    PORT MAP(
        clock_25Mhz     => clock_25Mhz,

        red             => r_vga,
        green           => g_vga,
        blue            => b_vga,

        red_out         => red_out,
        green_out       => green_out,
        blue_out        => blue_out,

        horiz_sync_out  => hsync_i,
        vert_sync_out   => vsync_i,

        pixel_row       => pixel_row,
        pixel_column    => pixel_column
    );

    bg_unit : bg_renderer
    PORT MAP(
        clk          => clock_25Mhz,
        
        pixel_row    => pixel_row,
        pixel_column => pixel_column,
        
        scroll_en    => scroll_en,

        red          => bg_r,
        green        => bg_g,
        blue         => bg_b
    );


    pipe_unit : pipes_game
    PORT MAP(
        clk           => clock_25Mhz,
        vert_sync     => vsync_i,       
        
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

    falling_unit : falling
    PORT MAP(
        clk          => clock_25Mhz,
        vert_sync     => vsync_i,       
        
        lmsb => '0', -- Unused, tied low for now

        pixel_row     => pixel_row,
        pixel_column  => pixel_column,

        red           => rocket_r,
        green         => rocket_g,
        blue          => rocket_b
    );

    PROCESS(bg_r, bg_g, bg_b, pipe_r, pipe_g, pipe_b, pipe_on, rocket_r, rocket_g, rocket_b)
    BEGIN
        IF (rocket_r /= "0000" OR rocket_g /= "0000" OR rocket_b /= "0000") THEN
            r_vga <= rocket_r;
            g_vga <= rocket_g;
            b_vga <= rocket_b;
        ELSIF pipe_on = '1' THEN
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