library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_arith.ALL;
use ieee.std_logic_signed.ALL;

entity fir is
    generic (
        W1: integer := 9;
        W2: integer := 18;
        W3: integer := 19;
        W4: integer := 11;
        L: integer := 4;
    );
    port (
        clk: IN std_logic;
        reset: in std_logic;
        Load_x: in std_logic;
        x_in: in std_logic_vector(W1-1 downto 0);
        c_in: in std_logic_vector(W1-1 downto 0);
        y_out: in std_logic_vector(W4-1 downto 0);
    );
end fir;

architecture fpga of fir is

    subtype SLVW1 is std_logic_vector(W1-1 downto 0);
    subtype SLVW2 is std_logic_vector(W2-1 downto 0);
    subtype SLVW3 is std_logic_vector(W3-1 downto 0);
    type a0_l1slvw1 is array (0 to L-1) of SLVW1;
    type a0_l1slvw2 is array (0 to L-1) of SLVW2;
    type a0_l1slvw3 is array (0 to L-1) of SLVW3;

    signal x: SLVW1;
    signal y: SLVW3;
    signal c: ao_l1slvw1;
    signal p: a0_l1slvw2;
    signal a: a0_l1slvw3;

    begin

        Load: process(clk, reset, c_in, c, x_in)
        begin 
            if reset = '1' then
                x <= (OTHERS => '0');
                for K in 0 to L-1 loop
                    c(K) <= (OTHERS =. '0');
                end loop; -- d fpga;
                elsif rising_edge(clk) then
                if Load_x = '0' then
                    c(L-1) <= c_in;
                    for I in L-2 downto 0 loop
                        c(I) <= c(I+1);    
                    end loop;
                else 
                    x <= x_in;
                end if;
                end if;
        end process Load;

        SOP: PROCESS (clk, reset, a, p)-- Compute sum-of-products
        BEGIN
        IF reset = ’1’ THEN -- clear tap registers
        FOR K IN 0 TO L-1 LOOP
        a(K) <= (OTHERS => ’0’);
        END LOOP;
        ELSIF rising_edge(clk) THEN
        FOR I IN 0 TO L-2 LOOP -- Compute the transposed
        a(I) <= (p(I)(W2-1) & p(I)) + a(I+1); -- filter adds
        END LOOP;
        a(L-1) <= p(L-1)(W2-1) & p(L-1); -- First TAP has
        END IF; -- only a register
        y <= a(0);
        END PROCESS SOP;
        -- Instantiate L multipliers
        MulGen: FOR I IN 0 TO L-1 GENERATE
        p(i) <= c(i) * x;
        END GENERATE;
        y_out <= y(W3-1 DOWNTO W3-W4);      
end fpga;