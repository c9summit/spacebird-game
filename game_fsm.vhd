LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_SIGNED.all;

entity game_fsm is
    port (
        clk,pb0, pb1, pb2, pb3, sw0, life_zero : in std_logic;
        game_state : out std_logic_vector(1 downto 0);
        scroll_en, score_rst, training : out std_logic);
end game_fsm;

architecture behaviour of game_fsm is

    CONSTANT MENU_SCRN : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
    CONSTANT PLAY_SCRN : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";
    CONSTANT PAUSE_SCRN : STD_LOGIC_VECTOR(1 DOWNTO 0) := "10";
    CONSTANT OVER_SCRN : STD_LOGIC_VECTOR(1 DOWNTO 0) := "11";

    signal current_state : std_logic_vector(1 downto 0) := MENU_SCRN;
    signal game_mode : std_logic := '1';
    
    signal pb0_prev, pb1_prev, pb2_prev, pb3_prev : std_logic := '1';
    signal pb0_press, pb1_press, pb2_press, pb3_press : std_logic := '0';

begin
    pb0_press <= '1' when (pb0 = '0' and pb0_prev = '1') else '0';
    pb1_press <= '1' when (pb1 = '0' and pb1_prev = '1') else '0';
    pb2_press <= '1' when (pb2 = '0' and pb2_prev = '1') else '0';
    pb3_press <= '1' when (pb3 = '0' and pb3_prev = '1') else '0';

    process(clk)
    begin
        if rising_edge(clk) then
            pb0_prev <= pb0;
            pb1_prev <= pb1;
            pb2_prev <= pb2;
            pb3_prev <= pb3;

            score_rst <= '0';

            case current_state is
                when MENU_SCRN =>
                    if pb0_press = '1' then
                        game_mode <= sw0;
                        score_rst <= '1';
                        current_state <= PLAY_SCRN;
                    end if;

                when PLAY_SCRN =>
                    if pb1_press = '1' then
                        current_state <= PAUSE_SCRN;
                    elsif life_zero = '1' then
                        current_state <= OVER_SCRN;
                    end if;

                when PAUSE_SCRN =>
                    if pb1_press = '1' then
                        current_state <= PLAY_SCRN;
                    elsif pb2_press = '1' then
                        current_state <= MENU_SCRN;
                        score_rst <= '1';
                    end if;

                when OVER_SCRN =>
                    if pb3_press = '1' then
                        current_state <= MENU_SCRN;
                        score_rst <= '1';
                    end if;

                when others =>
                    current_state <= MENU_SCRN;
            end case;
        end if;
    end process;

    game_state <= current_state;
    scroll_en <= '1' when current_state = PLAY_SCRN else '0';
    training <= game_mode;

end behaviour;