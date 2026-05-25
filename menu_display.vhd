LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY menu_display IS
    PORT(
        clk          : IN  STD_LOGIC;
        pixel_row    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        sw0          : IN  STD_LOGIC; -- '0' = game mode, '1' = training mode
        menu_on      : OUT STD_LOGIC;
        red          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        green        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        blue         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END menu_display;

ARCHITECTURE behaviour OF menu_display IS

    COMPONENT char_rom IS
    PORT(
        character_address : IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
        font_row          : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        font_col          : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        clock             : IN  STD_LOGIC;
        rom_mux_output    : OUT STD_LOGIC
    );
    END COMPONENT;

    -- Title: "SPACE BIRD" - 10 chars, 16px wide each (scale 2), 16px tall
    CONSTANT TITLE_X  : INTEGER := 200;
    CONSTANT TITLE_Y  : INTEGER := 100;
    CONSTANT TITLE_CW : INTEGER := 16;
    CONSTANT TITLE_CH : INTEGER := 16;

    -- Mode boxes
    CONSTANT BOX_X       : INTEGER := 220;
    CONSTANT BOX_W       : INTEGER := 200;
    CONSTANT BOX_H       : INTEGER := 40;
    CONSTANT GAME_BOX_Y  : INTEGER := 180;
    CONSTANT TRAIN_BOX_Y : INTEGER := 260;

    -- "GAME MODE" text (9 chars x 8px)
    CONSTANT GAME_TEXT_X : INTEGER := 248;
    CONSTANT GAME_TEXT_Y : INTEGER := 196;

    -- "TRAINING MODE" text (13 chars x 8px)
    CONSTANT TRAIN_TEXT_X : INTEGER := 228;
    CONSTANT TRAIN_TEXT_Y : INTEGER := 276;

    -- "PRESS START" text (11 chars x 8px)
    CONSTANT PS_X : INTEGER := 230;
    CONSTANT PS_Y : INTEGER := 380;

    -- Title ROM
    SIGNAL title_char_addr : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL title_font_r    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL title_font_c    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL title_pixel     : STD_LOGIC;
    SIGNAL title_rel_col   : INTEGER;
    SIGNAL title_rel_row   : INTEGER;
    SIGNAL title_char_idx  : INTEGER;
    SIGNAL in_title        : STD_LOGIC;

    -- Game mode ROM
    SIGNAL game_char_addr  : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL game_font_r     : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL game_font_c     : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL game_pixel      : STD_LOGIC;
    SIGNAL game_rel_col    : INTEGER;
    SIGNAL game_rel_row    : INTEGER;
    SIGNAL game_char_idx   : INTEGER;
    SIGNAL in_game_text    : STD_LOGIC;

    -- Training mode ROM
    SIGNAL train_char_addr : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL train_font_r    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL train_font_c    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL train_pixel     : STD_LOGIC;
    SIGNAL train_rel_col   : INTEGER;
    SIGNAL train_rel_row   : INTEGER;
    SIGNAL train_char_idx  : INTEGER;
    SIGNAL in_train_text   : STD_LOGIC;

    -- Press start ROM
    SIGNAL ps_char_addr    : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL ps_font_r       : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL ps_font_c       : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL ps_pixel        : STD_LOGIC;
    SIGNAL ps_rel_col      : INTEGER;
    SIGNAL ps_rel_row      : INTEGER;
    SIGNAL ps_char_idx     : INTEGER;
    SIGNAL in_ps           : STD_LOGIC;

    -- Box regions
    SIGNAL in_game_box     : STD_LOGIC;
    SIGNAL in_train_box    : STD_LOGIC;

    SIGNAL pr : INTEGER;
    SIGNAL pc : INTEGER;

BEGIN

    pr <= CONV_INTEGER(UNSIGNED(pixel_row));
    pc <= CONV_INTEGER(UNSIGNED(pixel_column));

    ROM_TITLE : char_rom PORT MAP(
        character_address => title_char_addr,
        font_row          => title_font_r,
        font_col          => title_font_c,
        clock             => clk,
        rom_mux_output    => title_pixel
    );

    ROM_GAME : char_rom PORT MAP(
        character_address => game_char_addr,
        font_row          => game_font_r,
        font_col          => game_font_c,
        clock             => clk,
        rom_mux_output    => game_pixel
    );

    ROM_TRAIN : char_rom PORT MAP(
        character_address => train_char_addr,
        font_row          => train_font_r,
        font_col          => train_font_c,
        clock             => clk,
        rom_mux_output    => train_pixel
    );

    ROM_PS : char_rom PORT MAP(
        character_address => ps_char_addr,
        font_row          => ps_font_r,
        font_col          => ps_font_c,
        clock             => clk,
        rom_mux_output    => ps_pixel
    );

    -- Region detection
    in_title <= '1' WHEN (pr >= TITLE_Y AND pr < TITLE_Y + TITLE_CH AND
                          pc >= TITLE_X AND pc < TITLE_X + 10*TITLE_CW)
                ELSE '0';

    in_game_text <= '1' WHEN (pr >= GAME_TEXT_Y AND pr < GAME_TEXT_Y + 8 AND
                               pc >= GAME_TEXT_X AND pc < GAME_TEXT_X + 9*8)
                    ELSE '0';

    in_train_text <= '1' WHEN (pr >= TRAIN_TEXT_Y AND pr < TRAIN_TEXT_Y + 8 AND
                                pc >= TRAIN_TEXT_X AND pc < TRAIN_TEXT_X + 13*8)
                     ELSE '0';

    in_ps <= '1' WHEN (pr >= PS_Y AND pr < PS_Y + 8 AND
                       pc >= PS_X AND pc < PS_X + 11*8)
             ELSE '0';

    in_game_box  <= '1' WHEN (pr >= GAME_BOX_Y  AND pr < GAME_BOX_Y  + BOX_H AND
                               pc >= BOX_X AND pc < BOX_X + BOX_W)
                    ELSE '0';

    in_train_box <= '1' WHEN (pr >= TRAIN_BOX_Y AND pr < TRAIN_BOX_Y + BOX_H AND
                               pc >= BOX_X AND pc < BOX_X + BOX_W)
                    ELSE '0';

    -- Title addressing
    title_rel_col  <= pc - TITLE_X;
    title_rel_row  <= pr - TITLE_Y;
    title_char_idx <= title_rel_col / TITLE_CW;

    PROCESS(title_char_idx)
    BEGIN
        CASE title_char_idx IS
            WHEN 0 => title_char_addr <= CONV_STD_LOGIC_VECTOR(19, 6); -- S
            WHEN 1 => title_char_addr <= CONV_STD_LOGIC_VECTOR(16, 6); -- P
            WHEN 2 => title_char_addr <= CONV_STD_LOGIC_VECTOR(1,  6); -- A
            WHEN 3 => title_char_addr <= CONV_STD_LOGIC_VECTOR(3,  6); -- C
            WHEN 4 => title_char_addr <= CONV_STD_LOGIC_VECTOR(5,  6); -- E
            WHEN 5 => title_char_addr <= CONV_STD_LOGIC_VECTOR(32, 6); -- space
            WHEN 6 => title_char_addr <= CONV_STD_LOGIC_VECTOR(2,  6); -- B
            WHEN 7 => title_char_addr <= CONV_STD_LOGIC_VECTOR(9,  6); -- I
            WHEN 8 => title_char_addr <= CONV_STD_LOGIC_VECTOR(18, 6); -- R
            WHEN 9 => title_char_addr <= CONV_STD_LOGIC_VECTOR(4,  6); -- D
            WHEN OTHERS => title_char_addr <= CONV_STD_LOGIC_VECTOR(32, 6);
        END CASE;
    END PROCESS;

    title_font_r <= CONV_STD_LOGIC_VECTOR((title_rel_row / 2), 3);
    title_font_c <= CONV_STD_LOGIC_VECTOR((title_rel_col MOD TITLE_CW) / 2, 3);

    -- Game mode text addressing: "GAME MODE"
    game_rel_col  <= pc - GAME_TEXT_X;
    game_rel_row  <= pr - GAME_TEXT_Y;
    game_char_idx <= game_rel_col / 8;

    PROCESS(game_char_idx)
    BEGIN
        CASE game_char_idx IS
            WHEN 0 => game_char_addr <= CONV_STD_LOGIC_VECTOR(7,  6); -- G
            WHEN 1 => game_char_addr <= CONV_STD_LOGIC_VECTOR(1,  6); -- A
            WHEN 2 => game_char_addr <= CONV_STD_LOGIC_VECTOR(13, 6); -- M
            WHEN 3 => game_char_addr <= CONV_STD_LOGIC_VECTOR(5,  6); -- E
            WHEN 4 => game_char_addr <= CONV_STD_LOGIC_VECTOR(32, 6); -- space
            WHEN 5 => game_char_addr <= CONV_STD_LOGIC_VECTOR(13, 6); -- M
            WHEN 6 => game_char_addr <= CONV_STD_LOGIC_VECTOR(15, 6); -- O
            WHEN 7 => game_char_addr <= CONV_STD_LOGIC_VECTOR(4,  6); -- D
            WHEN 8 => game_char_addr <= CONV_STD_LOGIC_VECTOR(5,  6); -- E
            WHEN OTHERS => game_char_addr <= CONV_STD_LOGIC_VECTOR(32, 6);
        END CASE;
    END PROCESS;

    game_font_r <= CONV_STD_LOGIC_VECTOR(game_rel_row, 3);
    game_font_c <= CONV_STD_LOGIC_VECTOR(game_rel_col MOD 8, 3);

    -- Training mode text addressing: "TRAINING MODE"
    train_rel_col  <= pc - TRAIN_TEXT_X;
    train_rel_row  <= pr - TRAIN_TEXT_Y;
    train_char_idx <= train_rel_col / 8;

    PROCESS(train_char_idx)
    BEGIN
        CASE train_char_idx IS
            WHEN 0  => train_char_addr <= CONV_STD_LOGIC_VECTOR(20, 6); -- T
            WHEN 1  => train_char_addr <= CONV_STD_LOGIC_VECTOR(18, 6); -- R
            WHEN 2  => train_char_addr <= CONV_STD_LOGIC_VECTOR(1,  6); -- A
            WHEN 3  => train_char_addr <= CONV_STD_LOGIC_VECTOR(9,  6); -- I
            WHEN 4  => train_char_addr <= CONV_STD_LOGIC_VECTOR(14, 6); -- N
            WHEN 5  => train_char_addr <= CONV_STD_LOGIC_VECTOR(9,  6); -- I
            WHEN 6  => train_char_addr <= CONV_STD_LOGIC_VECTOR(14, 6); -- N
            WHEN 7  => train_char_addr <= CONV_STD_LOGIC_VECTOR(7,  6); -- G
            WHEN 8  => train_char_addr <= CONV_STD_LOGIC_VECTOR(32, 6); -- space
            WHEN 9  => train_char_addr <= CONV_STD_LOGIC_VECTOR(13, 6); -- M
            WHEN 10 => train_char_addr <= CONV_STD_LOGIC_VECTOR(15, 6); -- O
            WHEN 11 => train_char_addr <= CONV_STD_LOGIC_VECTOR(4,  6); -- D
            WHEN 12 => train_char_addr <= CONV_STD_LOGIC_VECTOR(5,  6); -- E
            WHEN OTHERS => train_char_addr <= CONV_STD_LOGIC_VECTOR(32, 6);
        END CASE;
    END PROCESS;

    train_font_r <= CONV_STD_LOGIC_VECTOR(train_rel_row, 3);
    train_font_c <= CONV_STD_LOGIC_VECTOR(train_rel_col MOD 8, 3);

    -- Press start text addressing: "PRESS START"
    ps_rel_col  <= pc - PS_X;
    ps_rel_row  <= pr - PS_Y;
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

    -- RGB output - no background, just boxes and text
    PROCESS(pr, pc, sw0,
            in_title, title_pixel,
            in_game_text, game_pixel,
            in_train_text, train_pixel,
            in_ps, ps_pixel,
            in_game_box, in_train_box)

        VARIABLE r, g, b  : STD_LOGIC_VECTOR(3 DOWNTO 0);
        VARIABLE pixel_active : STD_LOGIC;
        VARIABLE on_game_border  : BOOLEAN;
        VARIABLE on_train_border : BOOLEAN;

    BEGIN
        r := "0000"; g := "0000"; b := "0000";
        pixel_active := '0';

        on_game_border  := (in_game_box  = '1') AND
                           (pr = GAME_BOX_Y OR pr = GAME_BOX_Y  + BOX_H - 1 OR
                            pc = BOX_X     OR pc = BOX_X + BOX_W - 1 OR
                            pr = GAME_BOX_Y + 1  OR pr = GAME_BOX_Y  + BOX_H - 2 OR
                            pc = BOX_X + 1     OR pc = BOX_X + BOX_W - 2);

        on_train_border := (in_train_box = '1') AND
                           (pr = TRAIN_BOX_Y OR pr = TRAIN_BOX_Y + BOX_H - 1 OR
                            pc = BOX_X       OR pc = BOX_X + BOX_W - 1 OR
                            pr = TRAIN_BOX_Y + 1 OR pr = TRAIN_BOX_Y + BOX_H - 2 OR
                            pc = BOX_X + 1       OR pc = BOX_X + BOX_W - 2);

        -- Game mode box
        IF in_game_box = '1' THEN
            pixel_active := '1';
            IF sw0 = '0' THEN
                IF on_game_border THEN
                    r := "0000"; g := "1111"; b := "1111"; -- cyan border
                ELSE
                    r := "0000"; g := "0010"; b := "0110"; -- dark blue fill
                END IF;
            ELSE
                IF on_game_border THEN
                    r := "0100"; g := "0100"; b := "0110"; -- dim border
                ELSE
                    pixel_active := '0'; -- unselected fill = transparent
                END IF;
            END IF;
        END IF;

        -- Training mode box
        IF in_train_box = '1' THEN
            pixel_active := '1';
            IF sw0 = '1' THEN
                IF on_train_border THEN
                    r := "0000"; g := "1111"; b := "1111"; -- cyan border
                ELSE
                    r := "0000"; g := "0010"; b := "0110"; -- dark blue fill
                END IF;
            ELSE
                IF on_train_border THEN
                    r := "0100"; g := "0100"; b := "0110"; -- dim border
                ELSE
                    pixel_active := '0'; -- unselected fill = transparent
                END IF;
            END IF;
        END IF;

        -- White text on top
        IF in_title = '1' AND title_pixel = '1' THEN
            r := "1111"; g := "1111"; b := "1111";
            pixel_active := '1';
        END IF;

        IF in_game_text = '1' AND game_pixel = '1' THEN
            r := "1111"; g := "1111"; b := "1111";
            pixel_active := '1';
        END IF;

        IF in_train_text = '1' AND train_pixel = '1' THEN
            r := "1111"; g := "1111"; b := "1111";
            pixel_active := '1';
        END IF;

        IF in_ps = '1' AND ps_pixel = '1' THEN
            r := "1111"; g := "1111"; b := "1111";
            pixel_active := '1';
        END IF;

        red     <= r;
        green   <= g;
        blue    <= b;
        menu_on <= pixel_active;

    END PROCESS;

END behaviour;