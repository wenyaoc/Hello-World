LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY HelloWorld IS
	PORT(	nReset					:IN	std_logic;
			CLOCK_50					:IN	std_logic;
			LED						:OUT 	std_logic);
END HelloWorld;
ARCHITECTURE mixed OF HelloWorld IS
	COMPONENT morse IS
	PORT (nReset					:IN	std_logic;
			start						:IN	std_logic;
			letter					:IN	std_logic_vector(2 DOWNTO 0);
			CLOCK_50					:IN	std_logic;
			LED						:OUT 	std_logic);
	END COMPONENT;
	COMPONENT six_sec_clk IS
	PORT ( Clk_50 : IN STD_LOGIC ;
			 Clk : OUT STD_LOGIC);
	END COMPONENT;
	
	type STATE_TYPE is (Init, ST_H, ST_E, ST_L1, ST_L2, ST_O);
	signal y: STATE_TYPE;
	signal clk, start: std_logic;
	signal letter : std_LOGIC_VECTOR(2 DOWNTO 0);
BEGIN
	

	clock6: six_sec_clk PORT MAP (CLOCK_50, clk);
	FSM_transitions: PROCESS(clk, nReset)
	BEGIN
		IF nReset = '0' THEN y <= Init;
		ELSIF (clk'EVENT AND clk = '1') THEN 
			CASE y IS
				WHEN Init =>
					letter <= "000";
					start <= '0';
					y <= ST_H;
				WHEN ST_H =>
					letter <= "001";
					start <= '1';
					y <= ST_E;
				WHEN ST_E =>
					letter <= "001";
					start <= '1';
					y <= ST_L1;
				WHEN ST_L1 =>
					letter <= "001";
					start <= '1';
					y <= ST_L2;
				WHEN ST_L2 =>
					letter <= "001";
					start <= '1';
					y <= ST_O;
				WHEN ST_O =>
					letter <= "001";
					start <= '1';
					y <= Init;
			END CASE;
		END IF;
	END PROCESS;
	
	morse_output: morse PORT MAP (nReset,start,letter,CLOCK_50,LED);
	
END mixed;




LIBRARY ieee;
USE ieee.std_logic_1164.all;


ENTITY morse IS
	PORT(	nReset					:IN	std_logic;
			start						:IN	std_logic;
			letter					:IN	std_logic_vector(2 DOWNTO 0);
			CLOCK_50					:IN	std_logic;
			LED						:OUT 	std_logic);
END morse;

ARCHITECTURE mixed OF morse IS
	COMPONENT shiftrne IS
		GENERIC ( N : INTEGER := 4 ) ;
		PORT ( R : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0) ;
				 L, E, w : IN STD_LOGIC ;
				 Clock : IN STD_LOGIC ;
	 			 Q : BUFFER STD_LOGIC_VECTOR(N-1 DOWNTO 0) ) ;
	END COMPONENT;
	COMPONENT half_sec_timer IS
		PORT ( Clk, Start : IN STD_LOGIC ;
				 Done : OUT STD_LOGIC);
	END COMPONENT;
	SIGNAL Clk, w, z, SEnable, TStart, TDone : std_logic;
	SIGNAL LR, CR, QL, QC : std_logic_vector(3 DOWNTO 0); -- length and code values and shift register contents
	SIGNAL sel : std_logic_vector(2 DOWNTO 0);
	TYPE state_t IS (Init, Morse_1, Morse_2, Morse_3, Interval); -- add to state list as needed
	SIGNAL y_Q, Y_D : state_t;
BEGIN
	Clk <= CLOCK_50;
	w <= start; -- start signal
	sel <= letter(2 DOWNTO 0);

	LED <= z; -- Morse output symbol		
	
	WITH sel SELECT -- code register 0=dot, 1=dash, listed from lsb on right to msb on left
		CR <= "0000" WHEN "000", -- H 
				"0000" WHEN "001", -- E
				"0010" WHEN "010", -- L
				"0111" WHEN "011", -- O
				"0000" WHEN OTHERS;
				
	WITH sel SELECT	
		LR <= "1111" WHEN "000", -- length register in unary from lsb on right
				"0001" WHEN "001",
				"1111" WHEN "010",
				"0111" WHEN "011",
				"0000" WHEN OTHERS;
	
	LenReg: shiftrne PORT MAP (LR, w, SEnable, '0', Clk, QL);
	CodeReg: shiftrne PORT MAP (CR, w, SEnable, '0', Clk, QC);
	Timer: half_sec_timer PORT MAP (Clk, TStart, TDone);
	
	FSM_transitions: PROCESS (y_Q, w, QC, QL, TDone) 	-- add to sensitivity list as needed
		BEGIN
			CASE y_Q IS
				WHEN Init =>					-- add to state transitions as needed
					IF (w = '0') THEN
						Y_D <= Init;
					ELSE
						Y_D <= Interval;
					END IF;
				WHEN Morse_1 =>
					IF (TDone = '1') THEN
						Y_D <= Morse_2;
					ELSE
						Y_D <= Morse_1;
					END IF;
				WHEN Morse_2 =>
					IF (TDone = '1') THEN
						Y_D <= Morse_3;
					ELSE
						Y_D <= Morse_2;
					END IF;
				WHEN Morse_3 =>
					IF (TDone = '1') THEN
						Y_D <= Interval;
					ELSE
						Y_D <= Morse_3;
					END IF;
				WHEN Interval =>
					IF (QL(0) = '0') THEN
						Y_D <= Init;
					ELSE
						IF (TDone = '1') THEN
							IF (QC(0) = '0') THEN
								Y_D <= Morse_3;
							ELSE
								Y_D <= Morse_1;
							END IF;
						ELSE
							Y_D <= Interval;
						END IF;
					END IF;
										
			END CASE;
		END PROCESS;
		
		FSM_state: PROCESS (Clk, nReset)
			BEGIN
				IF (nReset = '0') THEN
					y_Q <= Init;
				ELSIF (Clk'event AND Clk = '1') THEN
					y_Q <= Y_D;
				END IF;
			END PROCESS;
			
		FSM_outputs: PROCESS (y_Q)			-- add to sensitivity list as needed
			BEGIN
				SEnable <= '0'; TStart <= '0'; z <= '0';
				CASE y_Q IS
					WHEN Init =>				-- add to output states as needed
						SEnable <= '1';		-- enable loading of shift registers
					WHEN Morse_3 =>
						SEnable <= TDone;
						z <= '1';
					WHEN Interval =>
						NULL;
					WHEN OTHERS =>
						z <= '1';
				END CASE;
			END PROCESS;

END mixed;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY shiftrne IS
	GENERIC ( N : INTEGER := 4 ) ;
	PORT ( R : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0) ;
			 L, E, w : IN STD_LOGIC ;
			 Clock : IN STD_LOGIC ;
			 Q : BUFFER STD_LOGIC_VECTOR(N-1 DOWNTO 0) ) ;
END shiftrne ;

ARCHITECTURE Behavior OF shiftrne IS
BEGIN
	PROCESS
	BEGIN
		WAIT UNTIL (Clock'EVENT AND Clock = '1');
		IF (E = '1') THEN 								-- only shift or load when enabled
			IF (L = '1') THEN 							-- 	depending upon the load signal
				Q <= R; 										-- 		either load a new word in parallel
			ELSE 												--		or
				Genbits: FOR i IN 0 TO N-2 LOOP 		-- 		shift the word to the right
					Q(i) <= Q(i+1);
				END LOOP;
				Q(N-1) <= w;
			END IF;
		END IF;
	END PROCESS;
END Behavior;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY half_sec_timer IS
	PORT ( Clk, Start : IN STD_LOGIC ;
			 Done : OUT STD_LOGIC);
END half_sec_timer;

ARCHITECTURE Behavior OF half_sec_timer IS
	SIGNAL Q : INTEGER RANGE 0 TO 25000000;
BEGIN
	PROCESS (Clk)
	BEGIN
		IF (Clk'event AND Clk = '1') THEN
			IF (Start = '1') THEN					-- initialize timer when Start asserted
				Done <= '0';
				Q <= 0;
			ELSIF (Q = 25000000) THEN				-- assert Done when 0.5 seconds elapsed
				Done <= '1';
				Q <= 0;
			ELSE											-- increment timer each cycle
				Done <= '0';
				Q <= Q + 1;
			END IF;
		END IF;
	END PROCESS;
END Behavior;



LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY six_sec_clk IS
	PORT ( Clk_50 : IN STD_LOGIC ;
			 Clk : BUFFER STD_LOGIC);
END six_sec_clk;

ARCHITECTURE Behavior OF six_sec_clk IS
	SIGNAL Q : INTEGER RANGE 0 TO 150000000;
BEGIN
	PROCESS (Clk_50)
	BEGIN
		IF (Clk_50'event AND Clk_50 = '1') THEN
			IF (Q = 150000000) THEN				
				Clk <= NOT Clk;
				Q <= 0;
			ELSE
				Q <= Q + 1;
			END IF;
		END IF;
	END PROCESS;
END Behavior;
