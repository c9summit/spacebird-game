LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pipes_only IS
    PORT(
        reset        : IN  STD_LOGIC;
        vert_sync    : IN  STD_LOGIC;
        pixel_row    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);

        pipe_red, pipe_green, pipe_blue : OUT STD_LOGIC_VECTOR (3 downto 0)
    );
END pipes_only;

ARCHITECTURE behaviour OF pipes_only IS

    CONSTANT SCREEN_W   : INTEGER := 640;
    CONSTANT SCREEN_H   : INTEGER := 480;
    CONSTANT PIPE_W     : INTEGER := 60;
    CONSTANT GAP_TOP    : INTEGER := 160;
    CONSTANT GAP_HEIGHT : INTEGER := 130;
    CONSTANT PIPE_SPEED : INTEGER := 2;

    SIGNAL pipe_x : INTEGER RANGE -100 TO 700 := SCREEN_W;
    SIGNAL pipe_on : STD_LOGIC := '0';

BEGIN

    --------------------------------------------------------------------
    -- Move pipe once per VGA frame
    --------------------------------------------------------------------
    PROCESS(reset, vert_sync)
    BEGIN
        IF reset = '1' THEN
            pipe_x <= SCREEN_W;

        ELSIF rising_edge(vert_sync) THEN

            IF pipe_x <= -PIPE_W THEN
                pipe_x <= SCREEN_W;
            ELSE
                pipe_x <= pipe_x - PIPE_SPEED;
            END IF;

        END IF;
    END PROCESS;

    --------------------------------------------------------------------
    -- Draw pipe
    --------------------------------------------------------------------
    PROCESS(pixel_row, pixel_column, pipe_x)
        VARIABLE pr : INTEGER;
        VARIABLE pc : INTEGER;
        VARIABLE gap_bottom : INTEGER;
    BEGIN
        pr := TO_INTEGER(UNSIGNED(pixel_row));
        pc := TO_INTEGER(UNSIGNED(pixel_column));

        gap_bottom := GAP_TOP + GAP_HEIGHT;

        pipe_on <= '0';

        IF pc >= pipe_x AND pc < pipe_x + PIPE_W THEN
            IF pr < GAP_TOP OR pr > gap_bottom THEN
                pipe_on <= '1';
            END IF;
        END IF;
    END PROCESS;

    --------------------------------------------------------------------
    -- Colour output
    -- Green pipes, black background
    --------------------------------------------------------------------
pipe_red   <= "0000" when pipe_on = '1' else "0000";
pipe_green <= "1001" when pipe_on = '1' else "0000";
pipe_blue  <= "0000" when pipe_on = '1' else "0000";

END behaviour;