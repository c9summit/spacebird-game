LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY powerup IS
    PORT(
        clk          : IN  STD_LOGIC;
        vert_sync    : IN  STD_LOGIC;
        scroll_en    : IN  STD_LOGIC;
        score_rst    : IN  STD_LOGIC;
        pass_count   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);

        pixel_row    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);

        powerup_hit  : IN  STD_LOGIC;
        powerup_on   : OUT STD_LOGIC;
        powerup_x    : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        powerup_y    : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        red          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        green        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        blue         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END powerup;

ARCHITECTURE behaviour OF powerup IS

    CONSTANT POWERUP_W   : INTEGER := 16;
    CONSTANT POWERUP_H   : INTEGER := 16;
    CONSTANT POWERUP_SPD : INTEGER := 12; 
    CONSTANT SCREEN_W    : INTEGER := 640;
    CONSTANT RESPAWN_COUNT : INTEGER := 20; -- pipes before respawn

    SIGNAL pu_x      : INTEGER RANGE -20 TO 700 := 700;
    SIGNAL pu_y      : INTEGER RANGE 0  TO 464  := 200;
    SIGNAL pu_active : STD_LOGIC := '0'; -- visible and moving
    SIGNAL pu_collected : STD_LOGIC := '0'; -- waiting to respawn

    SIGNAL lfsr      : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11001010";
    SIGNAL vsync_d   : STD_LOGIC := '0';

    -- Track pass_count to know when to respawn
    SIGNAL last_count : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL pipes_since_collect : INTEGER RANGE 0 TO 255 := 0;

    -- Heart pixel pattern 16x16
    -- Each row is 16 bits, '1' = draw pixel
    TYPE heart_pattern IS ARRAY(0 TO 15) OF STD_LOGIC_VECTOR(15 DOWNTO 0);
    CONSTANT HEART : heart_pattern := (
        "0000000000000000",  -- row 0
        "0011100111000000",  -- row 1
        "0111110111110000",  -- row 2  
        "1111111111111000",  -- row 3
        "1111111111111100",  -- row 4
        "1111111111111100",  -- row 5
        "1111111111111100",  -- row 6
        "0111111111111000",  -- row 7
        "0011111111110000",  -- row 8
        "0001111111100000",  -- row 9
        "0000111111000000",  -- row 10
        "0000011110000000",  -- row 11
        "0000001100000000",  -- row 12
        "0000000000000000",  -- row 13
        "0000000000000000",  -- row 14
        "0000000000000000"   -- row 15
    );

BEGIN

    PROCESS(clk)
        VARIABLE new_pipes : INTEGER;
    BEGIN
        IF rising_edge(clk) THEN
            vsync_d <= vert_sync;

            IF score_rst = '1' THEN
                pu_x              <= SCREEN_W + 200; -- start off screen
                pu_y              <= 200;
                pu_active         <= '0';
                pu_collected      <= '0';
                pipes_since_collect <= 0;
                last_count        <= (OTHERS => '0');
                lfsr              <= "11001010";

            ELSIF vsync_d = '0' AND vert_sync = '1' THEN

                -- Advance LFSR every frame
                lfsr <= lfsr(6 DOWNTO 0) &
                       (lfsr(7) XOR lfsr(5) XOR lfsr(4) XOR lfsr(3));

                -- Track pipes passed for respawn timer
                IF pass_count /= last_count THEN
                    last_count <= pass_count;
                    IF pu_collected = '1' THEN
                        pipes_since_collect <= pipes_since_collect + 1;
                    END IF;
                END IF;

                -- Respawn after 20 pipes
                IF pu_collected = '1' AND pipes_since_collect >= RESPAWN_COUNT THEN
                    pu_x              <= SCREEN_W;
                    -- Random Y from LFSR: range 20 to 440
                    pu_y              <= 20 + CONV_INTEGER(lfsr(5 DOWNTO 0)) * 6;
                    pu_active         <= '1';
                    pu_collected      <= '0';
                    pipes_since_collect <= 0;
                END IF;

                -- Collected by player: disappear and start respawn timer
                IF powerup_hit = '1' AND pu_active = '1' THEN
                    pu_active           <= '0';
                    pu_collected        <= '1';
                    pipes_since_collect <= 0;

                -- Move power up if active and not just collected
                ELSIF scroll_en = '1' AND pu_active = '1' THEN
                    IF pu_x <= -POWERUP_W THEN
                        -- Missed by player, start respawn timer
                        pu_active           <= '0';
                        pu_collected        <= '1';
                        pipes_since_collect <= 0;
                    ELSE
                        pu_x <= pu_x - POWERUP_SPD;
                    END IF;
                END IF;

            END IF;
        END IF;
    END PROCESS;

    -- Draw process
    PROCESS(pixel_row, pixel_column, pu_x, pu_y, pu_active)
        VARIABLE pr      : INTEGER;
        VARIABLE pc      : INTEGER;
        VARIABLE rel_r   : INTEGER;
        VARIABLE rel_c   : INTEGER;
        VARIABLE in_pu   : BOOLEAN;
    BEGIN
        pr    := CONV_INTEGER(UNSIGNED(pixel_row));
        pc    := CONV_INTEGER(UNSIGNED(pixel_column));
        in_pu := FALSE;

        red        <= "0000";
        green      <= "0000";
        blue       <= "0000";
        powerup_on <= '0';

        IF pu_active = '1' THEN
            IF pc >= pu_x AND pc < pu_x + POWERUP_W AND
               pr >= pu_y AND pr < pu_y + POWERUP_H THEN

                rel_r := pr - pu_y;
                rel_c := pc - pu_x;

                IF HEART(rel_r)(15 - rel_c) = '1' THEN
                    -- Bright red heart
                    red        <= "1111";
                    green      <= "0000";
                    blue       <= "0000";
                    powerup_on <= '1';
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Expose position for collision
    powerup_x <= CONV_STD_LOGIC_VECTOR(pu_x, 10);
    powerup_y <= CONV_STD_LOGIC_VECTOR(pu_y, 10);

END behaviour;