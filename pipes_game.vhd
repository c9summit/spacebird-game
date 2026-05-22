LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pipes_game IS
    PORT(
        clk          : IN  STD_LOGIC;
        reset        : IN  STD_LOGIC;
        vert_sync    : IN  STD_LOGIC;

        pixel_row    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);

        pipe_on      : OUT STD_LOGIC;
        pipe_red     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        pipe_green   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        pipe_blue    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END pipes_game;

ARCHITECTURE behaviour OF pipes_game IS

    --------------------------------------------------------------------
    -- Screen constants
    --------------------------------------------------------------------
    CONSTANT SCREEN_W   : INTEGER := 640;
    CONSTANT SCREEN_H   : INTEGER := 480;

    CONSTANT PIPE_W     : INTEGER := 60;
    CONSTANT GAP_HEIGHT : INTEGER := 130;
    CONSTANT PIPE_SPEED : INTEGER := 2;

    --------------------------------------------------------------------
    -- Pipe position
    --------------------------------------------------------------------
    SIGNAL pipe_x   : INTEGER RANGE -100 TO 700 := SCREEN_W;
    SIGNAL gap_top  : INTEGER RANGE 40 TO 300 := 160;

    --------------------------------------------------------------------
    -- 8-bit LFSR
    --------------------------------------------------------------------
    SIGNAL lfsr : STD_LOGIC_VECTOR(7 DOWNTO 0) := "10101101";

    --------------------------------------------------------------------
    -- VSYNC edge detect
    --------------------------------------------------------------------
    SIGNAL vsync_d : STD_LOGIC := '0';

    --------------------------------------------------------------------
    -- Pipe visible signal
    --------------------------------------------------------------------
    SIGNAL pipe_on_reg : STD_LOGIC := '0';

BEGIN

    --------------------------------------------------------------------
    -- Move pipes once per frame
    --------------------------------------------------------------------
    PROCESS(clk)
    BEGIN

        IF rising_edge(clk) THEN

            vsync_d <= vert_sync;

            IF reset = '1' THEN

                pipe_x  <= SCREEN_W;
                gap_top <= 160;
                lfsr    <= "10101101";

            ELSE

                --------------------------------------------------------
                -- Detect rising edge of VSYNC
                --------------------------------------------------------
                IF (vsync_d = '0' AND vert_sync = '1') THEN

                    ----------------------------------------------------
                    -- Update LFSR
                    ----------------------------------------------------
                    lfsr <= lfsr(6 DOWNTO 0) &
                           (lfsr(7) XOR lfsr(5) XOR
                            lfsr(4) XOR lfsr(3));

                    ----------------------------------------------------
                    -- Move pipe left
                    ----------------------------------------------------
                    IF pipe_x <= -PIPE_W THEN

                        pipe_x <= SCREEN_W;

                        ------------------------------------------------
                        -- Random gap height
                        ------------------------------------------------
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

                        pipe_x <= pipe_x - PIPE_SPEED;

                    END IF;

                END IF;

            END IF;

        END IF;

    END PROCESS;

    --------------------------------------------------------------------
    -- Draw pipes
    --------------------------------------------------------------------
    PROCESS(pixel_row, pixel_column, pipe_x, gap_top)

        VARIABLE pr : INTEGER;
        VARIABLE pc : INTEGER;

        VARIABLE gap_bottom : INTEGER;

    BEGIN

        pr := TO_INTEGER(UNSIGNED(pixel_row));
        pc := TO_INTEGER(UNSIGNED(pixel_column));

        gap_bottom := gap_top + GAP_HEIGHT;

        pipe_on_reg <= '0';

        ------------------------------------------------------------
        -- Pipe region
        ------------------------------------------------------------
        IF (pc >= pipe_x) AND
           (pc < pipe_x + PIPE_W) THEN

            --------------------------------------------------------
            -- Draw top and bottom pipes
            --------------------------------------------------------
            IF (pr < gap_top) OR
               (pr >= gap_bottom) THEN

                pipe_on_reg <= '1';

            END IF;

        END IF;

    END PROCESS;

    --------------------------------------------------------------------
    -- Outputs
    --------------------------------------------------------------------
    pipe_on <= pipe_on_reg;

    -- Green pipes only
    pipe_red   <= "0000" WHEN pipe_on_reg = '1' ELSE "0000";
    pipe_green <= "1111" WHEN pipe_on_reg = '1' ELSE "0000";
    pipe_blue  <= "0000" WHEN pipe_on_reg = '1' ELSE "0000";

END behaviour;