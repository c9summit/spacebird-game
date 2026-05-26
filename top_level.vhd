LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY top_level IS
    PORT(
        clock_25MHz : IN  STD_LOGIC;
        pb0, pb1, pb2, pb3 : IN STD_LOGIC;
        sw0         : IN  STD_LOGIC;
        lmsb        : IN  STD_LOGIC;  -- mouse left button
        red_out     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        green_out   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        blue_out    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        hsync       : OUT STD_LOGIC;
        vsync       : OUT STD_LOGIC
    );
END top_level;

ARCHITECTURE rtl OF top_level IS

    -- Component declarations
    COMPONENT VGA_SYNC IS
    PORT(
        clock_25Mhz    : IN  STD_LOGIC;
        red            : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        green          : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        blue           : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        red_out        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        green_out      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        blue_out       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        horiz_sync_out : OUT STD_LOGIC;
        vert_sync_out  : OUT STD_LOGIC;
        pixel_row      : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column   : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
    );
    END COMPONENT;

    COMPONENT bg_renderer IS
    PORT(
        clk          : IN  STD_LOGIC;
        pixel_row    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        scroll_en    : IN  STD_LOGIC;
        red          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        green        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        blue         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
    END COMPONENT;

    COMPONENT pipe_game IS
    PORT(
        clk            : IN  STD_LOGIC;
        vert_sync      : IN  STD_LOGIC;
        scroll_en      : IN  STD_LOGIC;
        training_mode  : IN  STD_LOGIC;
        score_rst      : IN  STD_LOGIC;
        pixel_row      : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column   : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        pipe_on        : OUT STD_LOGIC;
        pipe_red       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        pipe_green     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        pipe_blue      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        pipe_x_out     : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        gap_top_out    : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        gap_bot_out    : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        pass_count_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    END COMPONENT;

    COMPONENT falling IS
    PORT(
        clk          : IN  STD_LOGIC;
        vert_sync    : IN  STD_LOGIC;
        lmsb         : IN  STD_LOGIC;
        pixel_row    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        red          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        green        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        blue         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
    END COMPONENT;

    COMPONENT game_fsm IS
    PORT(
        clk           : IN  STD_LOGIC;
        pb0, pb1, pb2, pb3 : IN STD_LOGIC;
        sw0, life_zero : IN STD_LOGIC;
        game_state    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        training      : OUT STD_LOGIC;
        scroll_en     : OUT STD_LOGIC;
        score_rst     : OUT STD_LOGIC
    );
    END COMPONENT;

    COMPONENT menu_display IS
    PORT(
        clk          : IN  STD_LOGIC;
        pixel_row    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        sw0          : IN  STD_LOGIC;
        menu_on      : OUT STD_LOGIC;
        red          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        green        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        blue         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
    END COMPONENT;

    COMPONENT vga_display IS
    PORT(
        clk          : IN  STD_LOGIC;
        pixel_row    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        game_state   : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        bg_r, bg_g, bg_b         : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        menu_on                  : IN STD_LOGIC;
        menu_r, menu_g, menu_b   : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        pipe_on                  : IN STD_LOGIC;
        pipe_r, pipe_g, pipe_b   : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        rocket_r, rocket_g, rocket_b : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        pass_count   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        red, green, blue         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
    END COMPONENT;

    -- VGA signals
    SIGNAL pixel_row    : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL pixel_column : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL vsync_i      : STD_LOGIC;
    SIGNAL hsync_i      : STD_LOGIC;

    -- Final RGB to VGA_SYNC
    SIGNAL r_vga : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL g_vga : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL b_vga : STD_LOGIC_VECTOR(3 DOWNTO 0);

    -- Background
    SIGNAL bg_r : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL bg_g : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL bg_b : STD_LOGIC_VECTOR(3 DOWNTO 0);

    -- Menu
    SIGNAL menu_on : STD_LOGIC;
    SIGNAL menu_r  : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL menu_g  : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL menu_b  : STD_LOGIC_VECTOR(3 DOWNTO 0);

    -- Pipe
    SIGNAL pipe_on     : STD_LOGIC;
    SIGNAL pipe_r      : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL pipe_g      : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL pipe_b      : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL pipe_x      : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL gap_top     : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL gap_bot     : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL pass_count  : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- Rocket
    SIGNAL rocket_r : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL rocket_g : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL rocket_b : STD_LOGIC_VECTOR(3 DOWNTO 0);

    -- FSM outputs
    SIGNAL game_state : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL scroll_en  : STD_LOGIC;
    SIGNAL score_rst  : STD_LOGIC;
    SIGNAL training   : STD_LOGIC;
    SIGNAL life_zero  : STD_LOGIC := '0'; -- placeholder until life_ctrl written

BEGIN

    vsync <= vsync_i;
    hsync <= hsync_i;

    vga_unit : VGA_SYNC
    PORT MAP(
        clock_25Mhz    => clock_25MHz,
        red            => r_vga,
        green          => g_vga,
        blue           => b_vga,
        red_out        => red_out,
        green_out      => green_out,
        blue_out       => blue_out,
        horiz_sync_out => hsync_i,
        vert_sync_out  => vsync_i,
        pixel_row      => pixel_row,
        pixel_column   => pixel_column
    );

    fsm_unit : game_fsm
    PORT MAP(
        clk       => clock_25MHz,
        pb0       => pb0,
        pb1       => pb1,
        pb2       => pb2,
        pb3       => pb3,
        sw0       => sw0,
        life_zero => life_zero,
        game_state => game_state,
        training   => training,
        scroll_en  => scroll_en,
        score_rst  => score_rst
    );

    bg_unit : bg_renderer
    PORT MAP(
        clk          => clock_25MHz,
        pixel_row    => pixel_row,
        pixel_column => pixel_column,
        scroll_en    => scroll_en,
        red          => bg_r,
        green        => bg_g,
        blue         => bg_b
    );

    menu_unit : menu_display
    PORT MAP(
        clk          => clock_25MHz,
        pixel_row    => pixel_row,
        pixel_column => pixel_column,
        sw0          => sw0,
        menu_on      => menu_on,
        red          => menu_r,
        green        => menu_g,
        blue         => menu_b
    );

    pipe_unit : pipe_game
    PORT MAP(
        clk           => clock_25MHz,
        vert_sync     => vsync_i,
        scroll_en     => scroll_en,
        training_mode => training,
        score_rst     => score_rst,
        pixel_row     => pixel_row,
        pixel_column  => pixel_column,
        pipe_on       => pipe_on,
        pipe_red      => pipe_r,
        pipe_green    => pipe_g,
        pipe_blue     => pipe_b,
        pipe_x_out    => pipe_x,
        gap_top_out   => gap_top,
        gap_bot_out   => gap_bot,
        pass_count_out => pass_count
    );

    falling_unit : falling
    PORT MAP(
        clk          => clock_25MHz,
        vert_sync    => vsync_i,
        lmsb         => lmsb,
        pixel_row    => pixel_row,
        pixel_column => pixel_column,
        red          => rocket_r,
        green        => rocket_g,
        blue         => rocket_b
    );

    mux_unit : vga_display
    PORT MAP(
        clk          => clock_25MHz,
        pixel_row    => pixel_row,
        pixel_column => pixel_column,
        game_state   => game_state,
        bg_r         => bg_r,
        bg_g         => bg_g,
        bg_b         => bg_b,
        menu_on      => menu_on,
        menu_r       => menu_r,
        menu_g       => menu_g,
        menu_b       => menu_b,
        pipe_on      => pipe_on,
        pipe_r       => pipe_r,
        pipe_g       => pipe_g,
        pipe_b       => pipe_b,
        rocket_r     => rocket_r,
        rocket_g     => rocket_g,
        rocket_b     => rocket_b,
        pass_count   => pass_count,
        red          => r_vga,
        green        => g_vga,
        blue         => b_vga
    );

END rtl;