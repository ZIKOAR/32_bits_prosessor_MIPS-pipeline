library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;  

entity processeur_pipline is
    generic(n : integer := 32);
	

    Port (
	 
	 --test
	 out_alu,p_coun,data,inst: out std_logic_vector(n-1 downto 0);
	
	 
	 --INPUTS
        clock, run, reset : in std_logic;
        done_exe : buffer std_logic
    );
end processeur_pipline;

architecture Behavioral of processeur_pipline is
   
    --signals for fetch
    signal pc ,PC_D,pc_j,instruction,instruction_D,offset,offset_D: std_logic_vector(n-1 downto 0);
	 signal imm_i :std_logic_vector(13 downto 0);
	 signal imm_j :std_logic_vector(28 downto 0);
	 signal sel_pc:std_logic_vector(1 downto 0);
	 signal pc_ctr :std_logic;
	 --signals for decode
	 signal rs, rt, rd:std_logic_vector(4 downto 0);
	 signal w_regm,r_regm:std_logic;
	 signal sel_adr_wreg:std_logic_vector(1downto 0);
	 signal data_wreg,out1_wreg,out2_wreg: std_logic_vector(n-1 downto 0);
	 --signals for excute
	 signal in_alu1,in_alu2,out_alu1,out_alu2: std_logic_vector(n-1 downto 0);
	 signal sel_data_reg,sel_in_alu1,sel_in_alu2:std_logic_vector(1 downto 0);
	 signal op_code:std_logic_vector(4 downto 0);
	 --signals for RM
	 signal w_mem,r_mem:std_logic;
	 signal data_wmem,adress_mem,out_mem: std_logic_vector(n-1 downto 0);
	 signal sel_data_mem,sel_adress_mem:std_logic_vector(1 downto 0);
	 --signal for control
	 signal i: std_logic_vector(7 downto 0);
    --signals for flip-flop
	 
signal in_alu1_E, in_alu2_E, out_alu1_E, out_alu2_E: std_logic_vector(n-1 downto 0);
signal offset_E: std_logic_vector(n-1 downto 0);
signal rd_E: std_logic_vector(4 downto 0);
signal PC_E: std_logic_vector(n-1 downto 0);
signal op_code_D, op_code_E: std_logic_vector(4 downto 0);
signal w_reg_D, w_reg_E: std_logic;
signal sel_in_alu1_D, sel_in_alu1_E: std_logic_vector(1 downto 0);
signal sel_in_alu2_D, sel_in_alu2_E: std_logic_vector(1 downto 0);
signal w_mem_D, w_mem_E: std_logic;
signal r_mem_D, r_mem_E: std_logic;
signal sel_adress_mem_D, sel_adress_mem_E: std_logic_vector(1 downto 0);
signal sel_data_mem_D, sel_data_mem_E: std_logic_vector(1 downto 0);
signal sel_data_reg_D, sel_data_reg_E: std_logic_vector(1 downto 0);

signal out_alu1_RM, out_alu2_RM: std_logic_vector(n-1 downto 0);
signal in_alu2_RM: std_logic_vector(n-1 downto 0);
signal PC_RM: std_logic_vector(n-1 downto 0);
signal rd_D,rd_RM: std_logic_vector(4 downto 0);
signal w_reg_RM: std_logic;
signal r_mem_RM, w_mem_RM: std_logic;
signal sel_adress_mem_RM, sel_data_mem_RM: std_logic_vector(1 downto 0);
signal sel_data_reg_RM: std_logic_vector(1 downto 0);

signal PC_WB: std_logic_vector(n-1 downto 0);
signal rd_WB: std_logic_vector(4 downto 0);
signal w_reg_WB: std_logic;
signal out_alu1_WB, out_alu2_WB: std_logic_vector(n-1 downto 0);
signal out_mem_WB: std_logic_vector(n-1 downto 0);
signal sel_data_reg_WB: std_logic_vector(1 downto 0);

--  component
component Memoire_registres is 
    port (
        clk: in std_logic;
        reset: in std_logic;  
        write_bit,read_bit: in std_logic;              
        read_reg_1, read_reg_2, write_reg: in std_logic_vector(4 downto 0); 
        write_data: in std_logic_vector(31 downto 0);   
        read_data_1, read_data_2: out std_logic_vector(31 downto 0)      
    );
end  component;
component memoire_principale IS 
   
    PORT (
        clk,reset,RE ,   WE   : IN  std_logic;                              
        data_in , address  : IN  std_logic_vector(31 DOWNTO 0);       
        data_out : OUT std_logic_vector(31 DOWNTO 0)        
    );
END component;
component alu_main is
    port (
        clk, reset : in std_logic;
        OP_code   : in std_logic_vector(4 downto 0);
        in1, in2  : in std_logic_vector(31 downto 0);
        hi, lo    : out std_logic_vector(31 downto 0)
    );
end component;

begin

-- PC
p_coun<=PC;
imm_i<=instruction(13 downto 0);
offset <= (31 downto 14 => imm_i(13)) & imm_i; 
imm_j<=instruction(28 downto 0);
pc_j<=pc(31 downto 29) & imm_j;
process(clock, reset)
   
    variable prev_pc_j : std_logic_vector(pc'length-1 downto 0); 
begin

    if reset = '1' then
        pc <= (others => '0');
          
    elsif rising_edge(clock) then
        if done_exe = '0' then
            if run = '1' then
                pc <= (others => '0');  
            elsif pc_ctr='1'  then  
                case sel_pc is
                    when "00" => 
                        pc <= std_logic_vector(signed(pc) + 1);  

                    when "01" =>
                        pc <= std_logic_vector(signed(pc) + signed(offset)); 

                    when "10" =>
                        pc <= pc_j;
						  when "11" =>
						      pc<=out1_wreg;
                end case;
            end if;
           
        end if;
        
    end if;
end process;

data<=data_wreg;
--PROCESS TO CONTROL THE PC
PROCESS(clock,reset)
variable num_f :integer:=0;
begin
if reset='1' then
sel_pc<="00";pc_ctr<='1';

elsif falling_edge(clock) then

	case i(7 downto 6) is
		when "00" => sel_pc<="00";pc_ctr<='1';num_f:=0;
		when "01" => case i is 
		           when "01001101" | "01001011" | "01001100"=>
						if (num_f >1) then
						num_f:=0;
						pc_ctr<='1';
						case i(1 downto 0) is
							when "01" =>sel_pc<="11";
							when "11" =>if(to_integer(signed(out_alu2))=0) then sel_pc<="01"; else sel_pc<="00"; end if;
							when "00" =>if(to_integer(signed(out_alu2))/=0) then sel_pc<="01"; else sel_pc<="00"; end if;
							when others =>null;
						end case; 
						else num_f:=num_f+1;pc_ctr<='0';
						end if;
						when others =>sel_pc<="00";pc_ctr<='1';num_f:=0;
						end case;
		when "10" => sel_pc<="10";pc_ctr<='1';num_f:=0;	
		
		when others =>sel_pc<="00";pc_ctr<='0';num_f:=0;

	end case;
	
end if;
end process;


done_exe<='1' when  i(7 downto 5)="111" else '0';

 
--Liaision pc et memoire_programme
mem_progrmme: entity work.Memoire_programme  port MAP (read_bit=>'1',read_adress=>pc,read_data=>instruction) ;
		
--liaison memoire programme et memoire registres
 inst<=instruction;

mem_registre:Memoire_registres  port MAP (clk=>clock,
        reset=>reset, 
        write_bit=>w_regm,read_bit=>r_regm,              
        read_reg_1=>rs, read_reg_2=>rt, write_reg=>rd,
        write_data=>data_wreg,
        read_data_1=>out1_wreg, read_data_2=>out2_wreg) ;
	
--liaison memoire registre et alu



			 
alu:alu_main  port MAP (clk=>clock,reset=>reset,OP_code=>op_code,in1=>in_alu1,in2=>in_alu2,
		hi=>out_alu1,lo=>out_alu2) ;

  -- control and test  OPCODE  sel_data_reg sel_in_alu2 sel_in_alu1
  	 
   out_alu<=out_alu2;	
	
	
--laison alu et memoire principale	
	
			 
mem_princupale:memoire_principale  port MAP (clk=>clock,reset=>reset,RE=> R_mem ,WE =>w_mem,                             
        data_in =>data_wmem, address=>adress_mem,data_out=>out_mem ) ;
	
	-----------PIPLINE------
	


i<=instruction(31 downto 24); 


		 

process(clock,reset)
	

begin
if reset='1' then
-- Réinitialisation des registres EX
        in_alu1_E <= (others=>'0');
        in_alu2_E <= (others=>'0');
		  offset_D <= (others=>'0');
        offset_E <= (others=>'0');
        rd_E <= (others=>'0');
        PC_E <= (others=>'0');
		  PC_D <= (others=>'0');
        op_code_E <= (others=>'0');
        w_reg_E <= '0';
        sel_in_alu1_E <= (others=>'0');
        sel_in_alu2_E <= (others=>'0');
        w_mem_E <= '0';
        r_mem_E <= '0';
        sel_adress_mem_E <= (others=>'0');
        sel_data_mem_E <= (others=>'0');
        sel_data_reg_E <= (others=>'0');
        -- Réinitialisation des registres RM
        out_alu1_RM <= (others=>'0');
        out_alu2_RM <= (others=>'0');
        in_alu2_RM <= (others=>'0');
        PC_RM <= (others=>'0');
        rd_RM <= (others=>'0');
        w_reg_RM <= '0';
        r_mem_RM <= '0';
        w_mem_RM <= '0';
        sel_adress_mem_RM <= (others=>'0');
        sel_data_mem_RM <= (others=>'0');
        sel_data_reg_RM <= (others=>'0');
        -- Réinitialisation des registres WB
        PC_WB <= (others=>'0');
        rd_WB <= (others=>'0');
        w_reg_WB <= '0';
        out_alu1_WB <= (others=>'0');
        out_alu2_WB <= (others=>'0');
        out_mem_WB <= (others=>'0');
        sel_data_reg_WB <= (others=>'0');
elsif rising_edge(clock) then 

pc_D<= std_logic_vector(signed(pc) + 1); 
offset_D<=offset;
in_alu1_E<=out1_wreg;
in_alu2_E<=out2_wreg;
offset_E<=offset_D;
rd_E<=rd_D;
PC_E<=PC_D;
op_code<=op_code_D;
w_reg_E<=w_reg_D;
sel_in_alu1_E<=sel_in_alu1_D;
sel_in_alu2_E<=sel_in_alu2_D;
w_mem_E<=w_mem_D;
r_mem_E<=r_mem_D;
sel_adress_mem_E<=sel_adress_mem_D;
sel_data_mem_E<=sel_data_mem_D;
sel_data_reg_E<=sel_data_reg_D;


out_alu1_RM<=out_alu1;
out_alu2_RM<=out_alu2;
in_alu2_RM<=in_alu2_E;
PC_RM<=PC_E;
rd_RM<=rd_E;
w_reg_RM<=w_reg_E;
r_mem_RM<=r_mem_E;
w_mem_RM<=w_mem_E;
sel_adress_mem_RM<=sel_adress_mem_E;
sel_data_mem_RM<=sel_data_mem_E;
sel_data_reg_RM<=sel_data_reg_E;

PC_WB<=PC_RM;
rd_WB<=rd_RM;
w_reg_WB<=w_reg_RM;
out_alu1_WB<=out_alu1_RM;
out_alu2_WB<=out_alu2_RM;
out_mem_WB<=out_mem;
sel_data_reg_WB<=sel_data_reg_RM;
end if;
end process;
process(clock,reset)
begin
    if reset='1' then 
	 instruction_D <= (others=>'0');
    elsif falling_edge(clock) then
        instruction_D <= instruction;
    end if;
end process;


		
in_alu1<= in_alu1_E when sel_in_alu1_E= "00" else
          --to be cntinued 
          (others=>'0');
in_alu2<= in_alu2_E when sel_in_alu2_E= "00" else
          offset_E when sel_in_alu2_E = "01" else
          --to be cntinued 
          (others=>'0');
		
	
data_wmem <= in_alu2_RM when sel_data_mem_RM="00" else
			--to be cntinued 
          (others=>'0');	
adress_mem	 <= out_alu2_RM when sel_adress_mem_RM= "00" else
			--to be cntinued 
          (others=>'0');	 



w_regm<=w_reg_WB;
rd<=rd_WB;
data_wreg<= out_alu2_WB when sel_data_reg_WB = "00" else
         out_alu1_WB when sel_data_reg_WB = "01" else
         out_mem_WB when sel_data_reg_WB = "10" else
			PC_WB;

	
process(clock,reset)
begin

if reset='1' then 

 w_reg_D<='1';
		sel_in_alu1_D<="00";
		sel_in_alu2_D<="00";
		w_mem_D<='0';r_mem_D<='0';
		sel_adress_mem_D<="00";
      sel_data_mem_D<="00";
      sel_data_reg_D<="00";      
       op_code_D<= (others => '0');
		rd_D<= (others => '0');
		r_regm<='1';
elsif rising_edge(clock) then 

rs<=instruction_D(23 downto 19); 
rt<=instruction_D(18 downto 14);


if i(i'left)='0' then
   --type R
	
	if i(6)='0' then
	   w_reg_D<='1';
		sel_in_alu1_D<="00";
		sel_in_alu2_D<="00";
		w_mem_D<='0';r_mem_D<='0';
		sel_adress_mem_D<="00";
      sel_data_mem_D<="00";
      sel_data_reg_D<="00";
		rd_D<=instruction_D(13 downto 9);
		case i is
			when "00000001" => op_code_D<= (others => '0');
			when "00000010" => op_code_D<= (0 => '1', others => '0');
			when "00000011" => op_code_D<= (1 => '1', others => '0');
			when "00000100" => op_code_D<= (1 => '1', 0 => '1', others => '0');
			when "00000101" => op_code_D<= "00110";
			when "00000110" => op_code_D<= "00111";
			when "00000111" => op_code_D<= "01000";
			when "00001000" => op_code_D<= "01011";
			when "00001001" => op_code_D<= "01010";
			when others     => op_code_D<= "11111";
      end case;
	--type I
	elsif i(3)='0' or i(3 downto 0)="1000" then
			 w_reg_D<='1';
			 sel_in_alu1_D<="00";
			 sel_in_alu2_D<="01";
			 w_mem_D<='0';r_mem_D<='0';
			 sel_adress_mem_D<="00";
			 sel_data_mem_D<="00";
			 sel_data_reg_D<="00";
			 rd_D<=instruction_D(18 downto 14);
			 
				case i is
					when "01000001" => op_code_D<= (others => '0');
					when "01000010" => op_code_D<= (0 => '1', others => '0');
					when "01000011" => op_code_D<= (1 => '1', others => '0');
					when "01000100" => op_code_D<= (1 => '1', 0 => '1', others => '0');
					when "01000101" => op_code_D<= "00110";
					when "01000110" => op_code_D<= "00111";
					when "01000111" => op_code_D<= "01000";
					when others     => op_code_D<= "11111";
				end case;
			
	
	else 
	
		case i is
		    when "01001001" => rd_D<=instruction_D(18 downto 14) ;
									  w_mem_D<='0';r_mem_D<='1';
									  op_code_D<= (others => '0');
									  w_reg_D<='1';
									  sel_in_alu1_D<="00";
									  sel_in_alu2_D<="01";
									  sel_adress_mem_D<="00";
									  sel_data_mem_D<="00";
									  sel_data_reg_D<="01";
			 when "01001010" => 
			                    w_mem_D<='1';r_mem_D<='0';
									  op_code_D<= (others => '0');
									  w_reg_D<='0';
									  sel_in_alu1_D<="00";
									  sel_in_alu2_D<="01";
									  sel_adress_mem_D<="00";
									  sel_data_mem_D<="01";
									  sel_data_reg_D<="00";
			 when "01001011" | "01001100"=> 
			                    w_mem_D<='0';r_mem_D<='0';
									  op_code_D<= "00100";
									  w_reg_D<='0';
									  sel_in_alu1_D<="00";
									  sel_in_alu2_D<="00";	
									  sel_adress_mem_D<="00";
									  sel_data_mem_D<="00";
									  sel_data_reg_D<="00";
				
			 when "01001101" =>
									  w_reg_D<='0';
									  sel_in_alu1_D<="00";
									  sel_in_alu2_D<="00";
									  w_mem_D<='0';r_mem_D<='0';
									  sel_adress_mem_D<="00";
									  sel_data_mem_D<="00";
									  sel_data_reg_D<="00";
			 when "01001000" => rd_D<=instruction_D(18 downto 14) ;
			 when others     =>
									  w_reg_D<='0';
									  sel_in_alu1_D<="00";
									  sel_in_alu2_D<="00";
									  w_mem_D<='0';r_mem_D<='0';
									  sel_adress_mem_D<="00";
									  sel_data_mem_D<="00";
									  sel_data_reg_D<="00";
		end case;
	
	end if;

else
--type J
 case i(7 downto 5) is 
	
	when "100"=> 
									  op_code_D<= (others => '0');
									  sel_adress_mem_D<="00";
									  sel_data_mem_D<="00";
									  sel_data_reg_D<="11";
									  w_reg_D<='0';
									  sel_in_alu1_D<="00";
									  sel_in_alu2_D<="00";
									  w_mem_D<='1';r_mem_D<='0';
	when "101"=>				  rd_D<="11110";w_reg_D<='1';
	when others => null;
    end case;
  end if;
end if;
end process;
end Behavioral;

--memoire_programme 
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity Memoire_programme is 
    port (
        read_bit: in std_logic;              
        read_adress: in std_logic_vector(31 downto 0);    
        read_data: out std_logic_vector(31 downto 0)      
    );
end Memoire_programme;
architecture beh of Memoire_programme is
	type mem_tab is array(0 to 127) of STD_LOGIC_VECTOR (31 downto 0);  
        signal my_mem: mem_tab := (
	  0 => "00000000000000000000000000000000",  
     1 => "01000001111110010100000000110111",  
     2 => "01000001111110000100000000000000", 
	  3 => "01000001111110001000000000000001",
	  4=>  "00000000000000000000000000000000",
	  5=>  "01001011000010010100000000000111",
	
	   6=> "01001011000100010100000000001000",
	  7 => "00000001000010001000001000000000",
	   8=> "00000000000000000000000000000000",
	 9=> "00000000000000000000000000000000",
	 10=> "00000001000010001000010000000000",
    11=> "10000000000000000000000000000101", 
	  12 => "00000001000011111100101000000000", 
	    13 => "10000000000000000000000000001111", 
		 14 => "00000001000101111100101000000000", 
		  15=> "11100000000000000000000000000000", 
others => "00000000000000000000000000000000" 
    );            
begin
process(read_adress)
    begin
            if read_bit = '1' then
				    read_data<= my_mem(to_integer(unsigned(read_adress)));
				end if; 
end process;
end beh;