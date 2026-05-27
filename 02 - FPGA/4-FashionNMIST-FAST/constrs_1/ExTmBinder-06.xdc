#--------------- RGB line 1 -----------------------------------------
set_property PACKAGE_PIN W16 [get_ports hub75_R1]
set_property IOSTANDARD LVCMOS33 [get_ports hub75_R1]

set_property PACKAGE_PIN W15 [get_ports hub75_G1]
set_property IOSTANDARD LVCMOS33 [get_ports hub75_G1]

set_property PACKAGE_PIN T15 [get_ports hub75_B1]
set_property IOSTANDARD LVCMOS33 [get_ports hub75_B1]

#--------------- RGB line 2 -----------------------------------------
set_property PACKAGE_PIN V15 [get_ports hub75_R2]
set_property IOSTANDARD LVCMOS33 [get_ports hub75_R2]

#set_property PACKAGE_PIN U15 [get_ports hub75_G2]
#set_property IOSTANDARD LVCMOS33 [get_ports hub75_G2]

#set_property PACKAGE_PIN V14 [get_ports hub75_B2]
#set_property IOSTANDARD LVCMOS33 [get_ports hub75_B2]

#--------------- RGB Address line------------------------------------
#set_property PACKAGE_PIN W12 [get_ports hub75_A]
#set_property IOSTANDARD LVCMOS33 [get_ports hub75_A]

#set_property PACKAGE_PIN W11 [get_ports hub75_B]
#set_property IOSTANDARD LVCMOS33 [get_ports hub75_B]

#set_property PACKAGE_PIN Y12 [get_ports hub75_C]
#set_property IOSTANDARD LVCMOS33 [get_ports hub75_C]

#set_property PACKAGE_PIN Y11 [get_ports hub75_D]
#set_property IOSTANDARD LVCMOS33 [get_ports hub75_D]

#set_property PACKAGE_PIN V13 [get_ports hub75_E]
#set_property IOSTANDARD LVCMOS33 [get_ports hub75_E]

#--------------- RGB Control ----------------------------------------
#set_property PACKAGE_PIN W10 [get_ports hub75_CLK]
#set_property IOSTANDARD LVCMOS33 [get_ports hub75_CLK]

#set_property PACKAGE_PIN V10 [get_ports hub75_LAT]
#set_property IOSTANDARD LVCMOS33 [get_ports hub75_LAT]

#set_property PACKAGE_PIN AA10 [get_ports hub75_OE]
#set_property IOSTANDARD LVCMOS33 [get_ports hub75_OE]

#activation du clock - 200MHZ
set_property IOSTANDARD LVDS_25 [get_ports clk_in1_p]
set_property IOSTANDARD LVDS_25 [get_ports clk_in1_n]

#--------------- Binder Control--------------------------------------
set_property PACKAGE_PIN L19 [get_ports switch]
set_property IOSTANDARD LVCMOS33 [get_ports switch]

set_property PACKAGE_PIN L20 [get_ports switchDisp]
set_property IOSTANDARD LVCMOS33 [get_ports switchDisp]

#--------------- Binder Control-------------------------TIMMING------


#set_output_delay -clock [::get_clocks_ren clk_in1_p] -max -add_delay 2.000 [get_ports hub75_B1]
#set_output_delay -clock [::get_clocks_ren clk_in1_p] -min -add_delay 2.000 [get_ports hub75_G1]
#set_output_delay -clock [::get_clocks_ren clk_in1_p] -max -add_delay 2.000 [get_ports hub75_G1]
#set_output_delay -clock [::get_clocks_ren clk_in1_p] -min -add_delay 2.000 [get_ports hub75_R1]
#set_output_delay -clock [::get_clocks_ren clk_in1_p] -max -add_delay 2.000 [get_ports hub75_R1]
#set_output_delay -clock [::get_clocks_ren clk_in1_p] -min -add_delay 2.000 [get_ports hub75_R2]
#set_output_delay -clock [::get_clocks_ren clk_in1_p] -max -add_delay 2.000 [get_ports hub75_R2]



create_clock -period 10.000 -name clk_in1_n -waveform {0.000 5.000}
create_clock -period 10.000 -name clk_in1_p -waveform {0.000 5.000}
