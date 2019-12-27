set_location_assignment PIN_N2 -to clock_50M

set_location_assignment PIN_N25 -to rst_n         
set_location_assignment PIN_N26 -to set  
set_location_assignment PIN_C13  -to append        
set_location_assignment PIN_AE14 -to Add           
set_location_assignment PIN_AF14 -to Sub          
set_location_assignment PIN_AD13 -to Mul          
set_location_assignment PIN_AC13 -to Div          
#rst_n:SW0
#set:SW1
#append:SW7
#Add:SW3
#Sub:SW4A
#Mul:SW5
#Div:SW6      

set_location_assignment PIN_V2 -to KEY[0]         
set_location_assignment PIN_V1 -to KEY[1]         
set_location_assignment PIN_U4 -to KEY[2]          
set_location_assignment PIN_U3 -to KEY[3]          
set_location_assignment PIN_T7 -to KEY[4]         
set_location_assignment PIN_P2 -to KEY[5]         
set_location_assignment PIN_P1 -to KEY[6]         
set_location_assignment PIN_N1 -to KEY[7]          
set_location_assignment PIN_A13 -to KEY[8]
set_location_assignment PIN_B13 -to KEY[9]
# KEY:SW17~SW9,分别表示0~9

set_location_assignment PIN_L4 -to lcd_p
set_location_assignment PIN_K2 -to lcd_n
set_location_assignment PIN_K1 -to lcd_rs
set_location_assignment PIN_K4 -to lcd_rw
set_location_assignment PIN_K3 -to lcd_en
set_location_assignment PIN_J1 -to lcd_data[0]
set_location_assignment PIN_J2 -to lcd_data[1]
set_location_assignment PIN_H1 -to lcd_data[2]
set_location_assignment PIN_H2 -to lcd_data[3]
set_location_assignment PIN_J4 -to lcd_data[4]
set_location_assignment PIN_J3 -to lcd_data[5]
set_location_assignment PIN_H4 -to lcd_data[6]
set_location_assignment PIN_H3 -to lcd_data[7]

set_location_assignment PIN_AE23 -to led_state[0]
set_location_assignment PIN_AF23 -to led_state[1]
set_location_assignment PIN_AB21 -to led_state[2]
set_location_assignment PIN_AC22 -to led_state[3]
set_location_assignment PIN_AD22 -to led_state[4]

set_location_assignment PIN_AD12 -to led_bits[0]
set_location_assignment PIN_AE12 -to led_bits[1]
set_location_assignment PIN_AE13 -to led_bits[2]
set_location_assignment PIN_AF13 -to led_bits[3]

set_location_assignment PIN_AE15 -to led_start_bits[0]
set_location_assignment PIN_AD15 -to led_start_bits[1]
set_location_assignment PIN_AC14 -to led_start_bits[2]
set_location_assignment PIN_AA13 -to led_start_bits[3]

set_location_assignment PIN_AE22 -to led_value[0]
set_location_assignment PIN_AF22 -to led_value[1]
set_location_assignment PIN_W19 -to led_value[2]
set_location_assignment PIN_V18 -to led_value[3]
set_location_assignment PIN_U18 -to led_value[4]
set_location_assignment PIN_U17 -to led_value[5]
set_location_assignment PIN_AA20 -to led_value[6]
set_location_assignment PIN_Y18 -to led_value[7]