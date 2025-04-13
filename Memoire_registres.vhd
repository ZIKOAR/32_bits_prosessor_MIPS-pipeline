library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Memoire_registres is 
    port (
        clk: in std_logic;
        reset: in std_logic;  
        write_bit, read_bit: in std_logic;              
        read_reg_1, read_reg_2, write_reg: in std_logic_vector(4 downto 0); 
        write_data: in std_logic_vector(31 downto 0);   
        read_data_1, read_data_2: out std_logic_vector(31 downto 0)      
    );
end Memoire_registres;

architecture beh of Memoire_registres is

    type mem_tab is array(0 to 31) of std_logic_vector(31 downto 0);  
    signal my_mem: mem_tab := (others => (others => '0'));            

begin
read_data_1 <= my_mem(to_integer(unsigned(read_reg_1))) when read_bit = '1' else (others => '0');
read_data_2 <= my_mem(to_integer(unsigned(read_reg_2))) when read_bit = '1' else (others => '0');

    process(clk, reset)
    begin
        if reset = '1' then
            for i in 0 to 31 loop
                my_mem(i) <= (others => '0');  
            end loop;
            
 
        elsif falling_edge(clk) then
            if write_bit = '1' and to_integer(unsigned(write_reg)) < 32 then
                my_mem(to_integer(unsigned(write_reg))) <= write_data;
            end if;
        end if;
    end process;

end beh;


