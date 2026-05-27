LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY life_ctrl IS
    PORT(
        clk         : IN  STD_LOGIC;
        score_rst   : IN  STD_LOGIC;

        pipe_hit    : IN  STD_LOGIC; -- lose 1 life
        floor_hit   : IN  STD_LOGIC; -- lose all lives instantly
        powerup_hit : IN  STD_LOGIC; -- gain 1 life

        lives       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0); -- current lives (0-5)
        life_zero   : OUT STD_LOGIC                     -- to game_fsm
    );
END life_ctrl;

ARCHITECTURE behaviour OF life_ctrl IS

    SIGNAL lives_reg : INTEGER RANGE 0 TO 5 := 3;

BEGIN

    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN

            IF score_rst = '1' THEN
                -- Reset to 3 lives on new game
                lives_reg <= 3;

            ELSE
                IF floor_hit = '1' THEN
                    -- Hit floor: instant game over
                    lives_reg <= 0;

                ELSIF pipe_hit = '1' AND powerup_hit = '0' THEN
                    -- Pipe hit only: lose a life
                    IF lives_reg > 0 THEN
                        lives_reg <= lives_reg - 1;
                    END IF;

                ELSIF powerup_hit = '1' AND pipe_hit = '0' THEN
                    -- Powerup only: gain a life (max 5)
                    IF lives_reg < 5 THEN
                        lives_reg <= lives_reg + 1;
                    END IF;

                -- If both pipe_hit and powerup_hit same frame, do nothing
                END IF;
            END IF;
        END IF;
    END PROCESS;

    lives     <= CONV_STD_LOGIC_VECTOR(lives_reg, 3);
    life_zero <= '1' WHEN lives_reg = 0 ELSE '0';

END behaviour;