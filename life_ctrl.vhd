LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY life_ctrl IS
    PORT(
        clk, score_rst : IN  STD_LOGIC;
        pipe_hit, floor_hit, powerup_hit : IN  STD_LOGIC;
        lives       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        life_zero   : OUT STD_LOGIC
    );
END life_ctrl;

ARCHITECTURE behaviour OF life_ctrl IS
    SIGNAL life_count : INTEGER RANGE 0 TO 5 := 3;
BEGIN
    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF score_rst = '1' THEN
                life_count <= 3;
            ELSE
                IF floor_hit = '1' THEN
                    life_count <= 0;
                ELSIF pipe_hit = '1' AND powerup_hit = '0' THEN
                    IF life_count > 0 THEN
                        life_count <= life_count - 1;
                    END IF;
                ELSIF powerup_hit = '1' AND pipe_hit = '0' THEN
                    IF life_count < 5 THEN
                        life_count <= life_count + 1;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    lives     <= CONV_STD_LOGIC_VECTOR(life_count, 3);
    life_zero <= '1' WHEN life_count = 0 ELSE '0';
END behaviour;