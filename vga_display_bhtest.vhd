Library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY vga_display_bhtest IS
    PORT(
        clk          : IN STD_LOGIC;
        pixel_row    : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
 
        game_state   : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
 
        -- Background
        bg_r, bg_g, bg_b     : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
 
        -- Menu
        menu_on              : IN STD_LOGIC;
        menu_r, menu_g, menu_b : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
 
        -- Pipe
        pipe_on              : IN STD_LOGIC;
        pipe_r, pipe_g, pipe_b : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
 
        -- Rocket
        rocket_r, rocket_g, rocket_b : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
 
        -- Score (pass_count from pipe_gen)
        pass_count   : IN STD_LOGIC_VECTOR(7 DOWNTO 0);

        -- Blackhole
        bh_on              : IN STD_LOGIC;
        bh_r, bh_g, bh_b   : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
 
        -- Final RGB output
        red, green, blue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END vga_display_bhtest;

architecture behaviour OF vga_display_bhtest IS

    component char_rom is
        PORT
	    (
		character_address	:	IN STD_LOGIC_VECTOR (5 DOWNTO 0);
		font_row, font_col	:	IN STD_LOGIC_VECTOR (2 DOWNTO 0);
		clock				: 	IN STD_LOGIC ;
		rom_mux_output		:	OUT STD_LOGIC
	);
    END component;

    CONSTANT MENU_SCRN : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
    CONSTANT PLAY_SCRN : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";
    CONSTANT PAUSE_SCRN : STD_LOGIC_VECTOR(1 DOWNTO 0) := "10";
    CONSTANT OVER_SCRN : STD_LOGIC_VECTOR(1 DOWNTO 0) := "11";

    -- Overlay box: centred 300x160 box
    CONSTANT OV_X  : INTEGER := 170;
    CONSTANT OV_Y  : INTEGER := 160;
    CONSTANT OV_W  : INTEGER := 300;
    CONSTANT OV_H  : INTEGER := 160;
 
    -- "PAUSED" text: 6 chars x 16px (scale 2), centred in box row 190
    CONSTANT PAUSE_TEXT_X : INTEGER := 224;
    CONSTANT PAUSE_TEXT_Y : INTEGER := 220;
 
    -- "GAME OVER" text: 9 chars x 16px (scale 2), row 185
    CONSTANT GO_TEXT_X : INTEGER := 192;
    CONSTANT GO_TEXT_Y : INTEGER := 185;
 
    -- "SCORE: XX" text: row 225
    CONSTANT SC_TEXT_X : INTEGER := 224;
    CONSTANT SC_TEXT_Y : INTEGER := 225;
 
    -- "PRESS START" text: row 265
    CONSTANT PS_TEXT_X : INTEGER := 208;
    CONSTANT PS_TEXT_Y : INTEGER := 265;

    constant BH_X : integer := 192;
    constant BH_Y : integer := 176;
 
    -- char_rom for PAUSED
    SIGNAL pause_char_addr : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL pause_font_r    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL pause_font_c    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL pause_pixel     : STD_LOGIC;
    SIGNAL pause_rel_col   : INTEGER;
    SIGNAL pause_rel_row   : INTEGER;
    SIGNAL pause_char_idx  : INTEGER;
    SIGNAL in_pause_text   : STD_LOGIC;
 
    -- char_rom for GAME OVER
    SIGNAL go_char_addr    : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL go_font_r       : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL go_font_c       : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL go_pixel        : STD_LOGIC;
    SIGNAL go_rel_col      : INTEGER;
    SIGNAL go_rel_row      : INTEGER;
    SIGNAL go_char_idx     : INTEGER;
    SIGNAL in_go_text      : STD_LOGIC;
 
    -- char_rom for SCORE
    SIGNAL sc_char_addr    : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL sc_font_r       : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL sc_font_c       : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL sc_pixel        : STD_LOGIC;
    SIGNAL sc_rel_col      : INTEGER;
    SIGNAL sc_rel_row      : INTEGER;
    SIGNAL sc_char_idx     : INTEGER;
    SIGNAL in_sc_text      : STD_LOGIC;
 
    -- char_rom for PRESS START
    SIGNAL ps_char_addr    : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL ps_font_r       : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL ps_font_c       : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL ps_pixel        : STD_LOGIC;
    SIGNAL ps_rel_col      : INTEGER;
    SIGNAL ps_rel_row      : INTEGER;
    SIGNAL ps_char_idx     : INTEGER;
    SIGNAL in_ps_text      : STD_LOGIC;
 
    -- Score digits
    SIGNAL score_tens : INTEGER RANGE 0 TO 9;
    SIGNAL score_units : INTEGER RANGE 0 TO 9;
 
    SIGNAL pr : INTEGER;
    SIGNAL pc : INTEGER;
    SIGNAL in_overlay : STD_LOGIC;
 
BEGIN
 
    pr <= CONV_INTEGER(UNSIGNED(pixel_row));
    pc <= CONV_INTEGER(UNSIGNED(pixel_column));
 
    -- Score digit extraction
    score_tens  <= CONV_INTEGER(UNSIGNED(pass_count)) / 10;
    score_units <= CONV_INTEGER(UNSIGNED(pass_count)) MOD 10;
 
    -- Overlay box region
    in_overlay <= '1' WHEN (pr >= OV_Y AND pr < OV_Y + OV_H AND
                             pc >= OV_X AND pc < OV_X + OV_W)
                  ELSE '0';
 
    -- char_rom instances
    ROM_PAUSE : char_rom PORT MAP(
        character_address => pause_char_addr,
        font_row => pause_font_r, 
        font_col => pause_font_c,
        clock => clk, 
        rom_mux_output => pause_pixel
    );
 
    ROM_GO : char_rom PORT MAP(
        character_address => go_char_addr,
        font_row => go_font_r, 
        font_col => go_font_c,
        clock => clk, 
        rom_mux_output => go_pixel
    );
 
    ROM_SC : char_rom PORT MAP(
        character_address => sc_char_addr,
        font_row => sc_font_r, 
        font_col => sc_font_c,
        clock => clk, 
        rom_mux_output => sc_pixel
    );
 
    ROM_PS : char_rom PORT MAP(
        character_address => ps_char_addr,
        font_row => ps_font_r, 
        font_col => ps_font_c,
        clock => clk, 
        rom_mux_output => ps_pixel
    );
 
    -- Region detection
    in_pause_text <= '1' WHEN (pr >= PAUSE_TEXT_Y AND pr < PAUSE_TEXT_Y + 16 AND
                                pc >= PAUSE_TEXT_X AND pc < PAUSE_TEXT_X + 6*16)
                     ELSE '0';
 
    in_go_text <= '1' WHEN (pr >= GO_TEXT_Y AND pr < GO_TEXT_Y + 16 AND
                             pc >= GO_TEXT_X AND pc < GO_TEXT_X + 9*16)
                  ELSE '0';
 
    -- "SCORE: XX" = 9 chars at scale 1
    in_sc_text <= '1' WHEN (pr >= SC_TEXT_Y AND pr < SC_TEXT_Y + 8 AND
                             pc >= SC_TEXT_X AND pc < SC_TEXT_X + 9*8)
                  ELSE '0';
 
    -- "PRESS START" = 11 chars at scale 1
    in_ps_text <= '1' WHEN (pr >= PS_TEXT_Y AND pr < PS_TEXT_Y + 8 AND
                             pc >= PS_TEXT_X AND pc < PS_TEXT_X + 11*8)
                  ELSE '0';
 
    -- PAUSED text addressing (scale 2)
    -- P=16 A=1 U=21 S=19 E=5 D=4
    pause_rel_col  <= pc - PAUSE_TEXT_X;
    pause_rel_row  <= pr - PAUSE_TEXT_Y;
    pause_char_idx <= pause_rel_col / 16;
 
    PROCESS(pause_char_idx)
    BEGIN
        CASE pause_char_idx IS
            WHEN 0 => pause_char_addr <= CONV_STD_LOGIC_VECTOR(16, 6); -- P
            WHEN 1 => pause_char_addr <= CONV_STD_LOGIC_VECTOR(1,  6); -- A
            WHEN 2 => pause_char_addr <= CONV_STD_LOGIC_VECTOR(21, 6); -- U
            WHEN 3 => pause_char_addr <= CONV_STD_LOGIC_VECTOR(19, 6); -- S
            WHEN 4 => pause_char_addr <= CONV_STD_LOGIC_VECTOR(5,  6); -- E
            WHEN 5 => pause_char_addr <= CONV_STD_LOGIC_VECTOR(4,  6); -- D
            WHEN OTHERS => pause_char_addr <= CONV_STD_LOGIC_VECTOR(32, 6);
        END CASE;
    END PROCESS;
 
    pause_font_r <= CONV_STD_LOGIC_VECTOR(pause_rel_row / 2, 3);
    pause_font_c <= CONV_STD_LOGIC_VECTOR((pause_rel_col MOD 16) / 2, 3);
 
    -- GAME OVER text addressing (scale 2)
    -- G=7 A=1 M=13 E=5 space=32 O=15 V=22 E=5 R=18
    go_rel_col  <= pc - GO_TEXT_X;
    go_rel_row  <= pr - GO_TEXT_Y;
    go_char_idx <= go_rel_col / 16;
 
    PROCESS(go_char_idx)
    BEGIN
        CASE go_char_idx IS
            WHEN 0 => go_char_addr <= CONV_STD_LOGIC_VECTOR(7,  6); -- G
            WHEN 1 => go_char_addr <= CONV_STD_LOGIC_VECTOR(1,  6); -- A
            WHEN 2 => go_char_addr <= CONV_STD_LOGIC_VECTOR(13, 6); -- M
            WHEN 3 => go_char_addr <= CONV_STD_LOGIC_VECTOR(5,  6); -- E
            WHEN 4 => go_char_addr <= CONV_STD_LOGIC_VECTOR(32, 6); -- space
            WHEN 5 => go_char_addr <= CONV_STD_LOGIC_VECTOR(15, 6); -- O
            WHEN 6 => go_char_addr <= CONV_STD_LOGIC_VECTOR(22, 6); -- V
            WHEN 7 => go_char_addr <= CONV_STD_LOGIC_VECTOR(5,  6); -- E
            WHEN 8 => go_char_addr <= CONV_STD_LOGIC_VECTOR(18, 6); -- R
            WHEN OTHERS => go_char_addr <= CONV_STD_LOGIC_VECTOR(32, 6);
        END CASE;
    END PROCESS;
 
    go_font_r <= CONV_STD_LOGIC_VECTOR(go_rel_row / 2, 3);
    go_font_c <= CONV_STD_LOGIC_VECTOR((go_rel_col MOD 16) / 2, 3);
 
    -- SCORE: XX text addressing (scale 1)
    -- S=19 C=3 O=15 R=18 E=5 colon=46 space=32 tens units
    sc_rel_col  <= pc - SC_TEXT_X;
    sc_rel_row  <= pr - SC_TEXT_Y;
    sc_char_idx <= sc_rel_col / 8;
 
    PROCESS(sc_char_idx, score_tens, score_units)
    BEGIN
        CASE sc_char_idx IS
            WHEN 0 => sc_char_addr <= CONV_STD_LOGIC_VECTOR(19, 6); -- S
            WHEN 1 => sc_char_addr <= CONV_STD_LOGIC_VECTOR(3,  6); -- C
            WHEN 2 => sc_char_addr <= CONV_STD_LOGIC_VECTOR(15, 6); -- O
            WHEN 3 => sc_char_addr <= CONV_STD_LOGIC_VECTOR(18, 6); -- R
            WHEN 4 => sc_char_addr <= CONV_STD_LOGIC_VECTOR(5,  6); -- E
            WHEN 5 => sc_char_addr <= CONV_STD_LOGIC_VECTOR(46, 6); -- :
            WHEN 6 => sc_char_addr <= CONV_STD_LOGIC_VECTOR(32, 6); -- space
            WHEN 7 => sc_char_addr <= CONV_STD_LOGIC_VECTOR(48 + score_tens,  6); -- tens digit
            WHEN 8 => sc_char_addr <= CONV_STD_LOGIC_VECTOR(48 + score_units, 6); -- units digit
            WHEN OTHERS => sc_char_addr <= CONV_STD_LOGIC_VECTOR(32, 6);
        END CASE;
    END PROCESS;
 
    sc_font_r <= CONV_STD_LOGIC_VECTOR(sc_rel_row, 3);
    sc_font_c <= CONV_STD_LOGIC_VECTOR(sc_rel_col MOD 8, 3);
 
    -- PRESS START text addressing (scale 1)
    -- P=16 R=18 E=5 S=19 S=19 space=32 S=19 T=20 A=1 R=18 T=20
    ps_rel_col  <= pc - PS_TEXT_X;
    ps_rel_row  <= pr - PS_TEXT_Y;
    ps_char_idx <= ps_rel_col / 8;
 
    PROCESS(ps_char_idx)
    BEGIN
        CASE ps_char_idx IS
            WHEN 0  => ps_char_addr <= CONV_STD_LOGIC_VECTOR(16, 6); -- P
            WHEN 1  => ps_char_addr <= CONV_STD_LOGIC_VECTOR(18, 6); -- R
            WHEN 2  => ps_char_addr <= CONV_STD_LOGIC_VECTOR(5,  6); -- E
            WHEN 3  => ps_char_addr <= CONV_STD_LOGIC_VECTOR(19, 6); -- S
            WHEN 4  => ps_char_addr <= CONV_STD_LOGIC_VECTOR(19, 6); -- S
            WHEN 5  => ps_char_addr <= CONV_STD_LOGIC_VECTOR(32, 6); -- space
            WHEN 6  => ps_char_addr <= CONV_STD_LOGIC_VECTOR(19, 6); -- S
            WHEN 7  => ps_char_addr <= CONV_STD_LOGIC_VECTOR(20, 6); -- T
            WHEN 8  => ps_char_addr <= CONV_STD_LOGIC_VECTOR(1,  6); -- A
            WHEN 9  => ps_char_addr <= CONV_STD_LOGIC_VECTOR(18, 6); -- R
            WHEN 10 => ps_char_addr <= CONV_STD_LOGIC_VECTOR(20, 6); -- T
            WHEN OTHERS => ps_char_addr <= CONV_STD_LOGIC_VECTOR(32, 6);
        END CASE;
    END PROCESS;
 
    ps_font_r <= CONV_STD_LOGIC_VECTOR(ps_rel_row, 3);
    ps_font_c <= CONV_STD_LOGIC_VECTOR(ps_rel_col MOD 8, 3);
 
    -- Main RGB output process
    PROCESS(game_state, pr, pc,
            bg_r, bg_g, bg_b,
            menu_on, menu_r, menu_g, menu_b,
            pipe_on, pipe_r, pipe_g, pipe_b,
            rocket_r, rocket_g, rocket_b,
            bh_on, bh_r, bh_g, bh_b,
            in_overlay, in_pause_text, pause_pixel,
            in_go_text, go_pixel,
            in_sc_text, sc_pixel,
            in_ps_text, ps_pixel)
 
        VARIABLE r, g, b : STD_LOGIC_VECTOR(3 DOWNTO 0);
        VARIABLE on_border : BOOLEAN;
 
    BEGIN
        r := "0000"; g := "0000"; b := "0000";
 
        CASE game_state IS
 
            -- MENU: bg + menu overlay
            WHEN MENU_SCRN =>
                r := bg_r; g := bg_g; b := bg_b;
                IF menu_on = '1' THEN
                    r := menu_r; g := menu_g; b := menu_b;
                END IF;
 
            -- PLAY: bg + pipes + rocket
            WHEN PLAY_SCRN =>
                r := bg_r; g := bg_g; b := bg_b;
                IF pipe_on = '1' THEN
                    r := pipe_r; g := pipe_g; b := pipe_b;
                END IF;
                IF rocket_r /= "0000" OR rocket_g /= "0000" OR rocket_b /= "0000" THEN
                    r := rocket_r; g := rocket_g; b := rocket_b;
                END IF;
                IF (pc >= bh_x AND pc < bh_x + 256 AND pr >= bh_y AND pr < bh_y + 128) THEN
                    IF bh_on = '1' THEN
                        r := bh_r;
                        g := bh_g;
                        b := bh_b;
                    END IF;
                END IF;
 
            -- PAUSE: bg + pipes + rocket + translucent box + PAUSED text
            WHEN PAUSE_SCRN =>
                r := bg_r; g := bg_g; b := bg_b;
                IF pipe_on = '1' THEN
                    r := pipe_r; g := pipe_g; b := pipe_b;
                END IF;
                IF rocket_r /= "0000" OR rocket_g /= "0000" OR rocket_b /= "0000" THEN
                    r := rocket_r; g := rocket_g; b := rocket_b;
                END IF;
                -- Checkerboard overlay for translucency
                IF in_overlay = '1' THEN
                    on_border := (pr = OV_Y OR pr = OV_Y + OV_H - 1 OR
                                  pc = OV_X OR pc = OV_X + OV_W - 1);
                    IF on_border THEN
                        -- Solid white border
                        r := "1111"; g := "1111"; b := "1111";
                    ELSIF (pr + pc) MOD 2 = 0 THEN
                        -- Checkerboard: dark blue on even pixels
                        r := "0000"; g := "0001"; b := "0011";
                    END IF;
                    -- Odd pixels show whatever was drawn underneath (bg/pipe/rocket)
                END IF;
                -- PAUSED text on top
                IF in_pause_text = '1' AND pause_pixel = '1' THEN
                    r := "1111"; g := "1111"; b := "1111";
                END IF;
 
            -- GAME OVER: bg + translucent box + GAME OVER + SCORE + PRESS START
            WHEN OVER_SCRN =>
                r := bg_r; g := bg_g; b := bg_b;
                IF in_overlay = '1' THEN
                    on_border := (pr = OV_Y OR pr = OV_Y + OV_H - 1 OR
                                  pc = OV_X OR pc = OV_X + OV_W - 1);
                    IF on_border THEN
                        r := "1111"; g := "1111"; b := "1111";
                    ELSIF (pr + pc) MOD 2 = 0 THEN
                        r := "0000"; g := "0001"; b := "0011";
                    END IF;
                END IF;
                IF in_go_text = '1' AND go_pixel = '1' THEN
                    r := "1111"; g := "1111"; b := "1111";
                END IF;
                IF in_sc_text = '1' AND sc_pixel = '1' THEN
                    r := "1111"; g := "1111"; b := "1111";
                END IF;
                IF in_ps_text = '1' AND ps_pixel = '1' THEN
                    r := "1111"; g := "0000"; b := "0000"; -- red press start
                END IF;
 
            WHEN OTHERS =>
                r := "0000"; g := "0000"; b := "0000";
 
        END CASE;
 
        red   <= r;
        green <= g;
        blue  <= b;
 
    END PROCESS;
 
END behaviour;