LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY collision IS
    PORT(
        clk, vert_sync, scroll_en : IN STD_LOGIC;
        ball_x_pos, ball_y_pos : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        pipe_x, gap_top, gap_bot : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        powerup_x, powerup_y : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        pipe_hit, powerup_hit : OUT STD_LOGIC);
END collision;

ARCHITECTURE behaviour OF collision IS

    -- Hitbox offsets left = 10, top = 3px)
    CONSTANT HB_X_OFFSET : STD_LOGIC_VECTOR(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(10, 10);
    CONSTANT HB_Y_OFFSET : STD_LOGIC_VECTOR(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(3,  10);
    CONSTANT HB_W : STD_LOGIC_VECTOR(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(18, 10);
    CONSTANT HB_H : STD_LOGIC_VECTOR(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(10, 10);
    CONSTANT PIPE_W : STD_LOGIC_VECTOR(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(50, 10);
    CONSTANT POWERUP_W : STD_LOGIC_VECTOR(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(16, 10);
    CONSTANT POWERUP_H : STD_LOGIC_VECTOR(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(16, 10);

    SIGNAL hb_left, hb_right, hb_top, hb_bottom : STD_LOGIC_VECTOR(9 DOWNTO 0);

    SIGNAL pipe_x_overlap, pipe_y_overlap, pipe_hit_raw : STD_LOGIC;
    SIGNAL pipe_collision_registered : STD_LOGIC := '0';

    SIGNAL pu_x_overlap, pu_y_overlap, pu_hit_raw : STD_LOGIC;
    SIGNAL pu_collision_registered : STD_LOGIC := '0';

    SIGNAL vsync_d : STD_LOGIC := '0';

BEGIN

    hb_left <= ball_x_pos + HB_X_OFFSET;
    hb_right <= ball_x_pos + HB_X_OFFSET + HB_W;
    hb_top <= ball_y_pos + HB_Y_OFFSET;
    hb_bottom <= ball_y_pos + HB_Y_OFFSET + HB_H;

    pipe_x_overlap <= '1' WHEN (hb_left < pipe_x + PIPE_W AND hb_right > pipe_x) ELSE '0';
    pipe_y_overlap <= '1' WHEN (hb_top < gap_top OR hb_bottom > gap_bot) ELSE '0';
    pipe_hit_raw <= '1' WHEN (pipe_x_overlap = '1' AND pipe_y_overlap = '1') ELSE '0';

    pu_x_overlap <= '1' WHEN (hb_left < powerup_x + POWERUP_W AND hb_right > powerup_x) ELSE '0';
    pu_y_overlap <= '1' WHEN (hb_top < powerup_y + POWERUP_H AND hb_bottom > powerup_y) ELSE '0';
    pu_hit_raw <= '1' WHEN (pu_x_overlap = '1' AND pu_y_overlap = '1') ELSE '0';

    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            vsync_d <= vert_sync;
            IF vsync_d = '0' AND vert_sync = '1' THEN
                IF pipe_x_overlap = '0' THEN
                    pipe_collision_registered <= '0';
                ELSIF pipe_hit_raw = '1' AND pipe_collision_registered = '0' THEN
                    pipe_collision_registered <= '1';
                END IF;
                IF pu_x_overlap = '0' THEN
                    pu_collision_registered <= '0';
                ELSIF pu_hit_raw = '1' AND pu_collision_registered = '0' THEN
                    pu_collision_registered <= '1';
                END IF;
            END IF;
        END IF;
    END PROCESS;

    pipe_hit <= '1' WHEN (pipe_hit_raw = '1' AND pipe_collision_registered = '0') ELSE '0';
    powerup_hit <= '1' WHEN (pu_hit_raw = '1' AND pu_collision_registered = '0') ELSE '0';

END behaviour;