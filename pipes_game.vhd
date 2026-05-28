LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY pipes_game IS
    PORT(
        clk, vert_sync, scroll_en, training_mode, score_rst : IN  STD_LOGIC;
        pixel_row, pixel_column : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        pipe_on : OUT STD_LOGIC;
        pipe_red, pipe_green, pipe_blue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        pipe_x_out, gap_top_out, gap_bot_out : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        pass_count_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END pipes_game;

ARCHITECTURE behaviour OF pipes_game IS

    CONSTANT SCREEN_W : INTEGER := 640;
    CONSTANT PIPE_W : INTEGER := 50; 
    CONSTANT GAP_HEIGHT : INTEGER := 130;

    CONSTANT TRAIN_SPEED : INTEGER := 1;
    CONSTANT MAX_SPEED : INTEGER := 15;

    SIGNAL pipe_x : INTEGER RANGE -100 TO 700 := SCREEN_W;
    SIGNAL gap_top : INTEGER RANGE 40  TO 310  := 160;

    SIGNAL lfsr : STD_LOGIC_VECTOR(7 DOWNTO 0) := "10101101";
    SIGNAL vsync_d : STD_LOGIC := '0';

    SIGNAL pass_count : INTEGER RANGE 0 TO 255 := 0;
    SIGNAL pipe_speed : INTEGER RANGE 1 TO 15 := TRAIN_SPEED;
    SIGNAL passed : STD_LOGIC := '0';

BEGIN
    PROCESS(training_mode, pass_count)
    BEGIN
        IF training_mode = '1' THEN
            pipe_speed <= TRAIN_SPEED;
        ELSE
            IF pass_count < 3 THEN
                pipe_speed <= 4;
            ELSIF pass_count < 6 THEN
                pipe_speed <= 6;
            ELSIF pass_count < 9 THEN
                pipe_speed <= 10;
            ELSIF pass_count < 12 THEN
                pipe_speed <= 13;
            ELSE
                pipe_speed <= MAX_SPEED;
            END IF;
        END IF;
    END PROCESS;

    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            vsync_d <= vert_sync;
            IF score_rst = '1' THEN
                pipe_x <= SCREEN_W;
                gap_top <= 160;
                lfsr <= "10101101";
                pass_count <= 0;
                passed <= '0';
            ELSIF scroll_en = '1' AND vsync_d = '0' AND vert_sync = '1' THEN
                lfsr <= lfsr(6 DOWNTO 0) &
                       (lfsr(7) XOR lfsr(5) XOR lfsr(4) XOR lfsr(3));
                IF pipe_x <= -PIPE_W THEN
                    pipe_x  <= SCREEN_W;
                    passed  <= '0';
                    CASE lfsr(2 DOWNTO 0) IS
                        WHEN "000" => gap_top <= 50;
                        WHEN "001" => gap_top <= 80;
                        WHEN "010" => gap_top <= 110;
                        WHEN "011" => gap_top <= 140;
                        WHEN "100" => gap_top <= 170;
                        WHEN "101" => gap_top <= 200;
                        WHEN "110" => gap_top <= 230;
                        WHEN OTHERS => gap_top <= 260;
                    END CASE;
                ELSE
                    pipe_x <= pipe_x - pipe_speed;
                    IF pipe_x < 0 AND passed = '0' THEN
                        pass_count <= pass_count + 1;
                        passed <= '1';
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    PROCESS(pixel_row, pixel_column, pipe_x, gap_top)
        VARIABLE pr, pc, gap_bottom : INTEGER;
        VARIABLE in_pipe, in_border : STD_LOGIC;
    BEGIN
        pr := CONV_INTEGER(UNSIGNED(pixel_row));
        pc := CONV_INTEGER(UNSIGNED(pixel_column));
        gap_bottom := gap_top + GAP_HEIGHT;
        in_pipe := '0';
        in_border := '0';

        IF pc >= pipe_x AND pc < pipe_x + PIPE_W THEN
            IF pr < gap_top OR pr >= gap_bottom THEN
                in_pipe := '1';
                IF pr = gap_top - 1 OR pr = gap_bottom OR pc = pipe_x OR pc = pipe_x + PIPE_W - 1 THEN
                    in_border := '1';
                END IF;
            END IF;
        END IF;
        IF in_pipe = '1' THEN
            IF in_border = '1' THEN
                pipe_red   <= "0000";
                pipe_green <= "1111";
                pipe_blue  <= "1111";
            ELSE
                pipe_red   <= "0010";
                pipe_green <= "0011";
                pipe_blue  <= "0101";
            END IF;
        pipe_on <= '1';
        ELSE
            pipe_red   <= "0000";
            pipe_green <= "0000";
            pipe_blue  <= "0000";
            pipe_on    <= '0';
        END IF;

    END PROCESS;

    pipe_x_out <= CONV_STD_LOGIC_VECTOR(pipe_x,  10);
    gap_top_out <= CONV_STD_LOGIC_VECTOR(gap_top,  10);
    gap_bot_out <= CONV_STD_LOGIC_VECTOR(gap_top + GAP_HEIGHT, 10);
    pass_count_out <= CONV_STD_LOGIC_VECTOR(pass_count, 8);

END behaviour;