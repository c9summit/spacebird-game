LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_SIGNED.all;

ENTITY falling IS
    PORT(lmsb, clk, vert_sync : IN STD_LOGIC;
        pixel_row, pixel_column : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        red, green, blue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END falling;

ARCHITECTURE behaviour OF falling IS

    COMPONENT sprite_rom IS
    PORT(
        address : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
        clock   : IN  STD_LOGIC;
        q       : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
    );
    END COMPONENT;

    SIGNAL ball_on       : STD_LOGIC;
    SIGNAL ball_y_pos    : STD_LOGIC_VECTOR(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(240, 10);
    SIGNAL ball_x_pos    : STD_LOGIC_VECTOR(10 DOWNTO 0);
    SIGNAL ball_y_motion : STD_LOGIC_VECTOR(9 DOWNTO 0);

    SIGNAL sprite_addr  : STD_LOGIC_VECTOR(8 DOWNTO 0);
    SIGNAL sprite_pixel : STD_LOGIC_VECTOR(11 DOWNTO 0);
    SIGNAL sprite_on    : STD_LOGIC;
    SIGNAL rel_col      : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL rel_row      : STD_LOGIC_VECTOR(3 DOWNTO 0);

    CONSTANT SPRITE_W : STD_LOGIC_VECTOR(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(32, 10);
    CONSTANT SPRITE_H : STD_LOGIC_VECTOR(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(16, 10);

BEGIN

    SPRITE : sprite_rom PORT MAP(
        address => sprite_addr,
        clock   => clk,
        q       => sprite_pixel
    );

    ball_x_pos <= CONV_STD_LOGIC_VECTOR(590, 11);

    ball_on <= '1' WHEN (
        pixel_column >= ball_x_pos(9 DOWNTO 0) AND
        pixel_column <  ball_x_pos(9 DOWNTO 0) + SPRITE_W AND
        pixel_row    >= ball_y_pos AND
        pixel_row    <  ball_y_pos + SPRITE_H)
        ELSE '0';

    rel_col <= pixel_column(4 DOWNTO 0) - ball_x_pos(4 DOWNTO 0);
    rel_row <= pixel_row(3 DOWNTO 0)    - ball_y_pos(3 DOWNTO 0);

    sprite_addr <= rel_row & rel_col;

    sprite_on <= '1' WHEN (ball_on = '1' AND sprite_pixel /= X"FFF") ELSE '0';

    Move_Ball: PROCESS(vert_sync)
    BEGIN
        IF rising_edge(vert_sync) THEN
            IF (ball_y_pos > CONV_STD_LOGIC_VECTOR(479, 10) - SPRITE_H) THEN
                ball_y_motion <= (OTHERS => '0');
                ball_y_pos    <= CONV_STD_LOGIC_VECTOR(479, 10) - SPRITE_H;
            ELSIF (ball_y_pos <= CONV_STD_LOGIC_VECTOR(0, 10)) THEN
                ball_y_motion <= ball_y_motion + CONV_STD_LOGIC_VECTOR(1, 10);
                ball_y_pos    <= ball_y_pos + ball_y_motion;
            ELSIF (lmsb = '1') THEN
                ball_y_motion <= -CONV_STD_LOGIC_VECTOR(4, 10);
                ball_y_pos    <= ball_y_pos + ball_y_motion;
            ELSE
                ball_y_motion <= ball_y_motion + CONV_STD_LOGIC_VECTOR(1, 10);
                ball_y_pos    <= ball_y_pos + ball_y_motion;
            END IF;
        END IF;
    END PROCESS Move_Ball;

    -- Sprite pixels: use full 4-bit colour from ROM
    -- Background: black when sprite not active
    red   <= sprite_pixel(11 DOWNTO 8) WHEN sprite_on = '1' ELSE "0000";
    green <= sprite_pixel(7  DOWNTO 4) WHEN sprite_on = '1' ELSE "0000";
    blue  <= sprite_pixel(3  DOWNTO 0) WHEN sprite_on = '1' ELSE "0000";

END behaviour;