transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/TOP {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/TOP/aes_uart_top.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_ENCRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_ENCRYPTION/code/AES_TOP.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_ENCRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_ENCRYPTION/code/keyExpansion.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_ENCRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_ENCRYPTION/code/mixColumns.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_ENCRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_ENCRYPTION/code/sbox.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_ENCRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_ENCRYPTION/code/shiftRows.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_ENCRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_ENCRYPTION/code/subBytes.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/UART_buffer/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/UART_buffer/code/Buffer_top.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/UART_buffer/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/UART_buffer/code/fifo_tx.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/UART_buffer/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/UART_buffer/code/UART_TX.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/UART_buffer/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/UART_buffer/code/UART_RX.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/UART_buffer/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/UART_buffer/code/fifo_rx.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_DECRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_DECRYPTION/code/ADS_TOP.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_DECRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_DECRYPTION/code/inverseShiftrows.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_DECRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_DECRYPTION/code/inverseSbox.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_DECRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_DECRYPTION/code/inverseSubBytes.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_DECRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/AES_DECRYPTION/code/invMixColumns.v}

vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES/TOP/../testbench {/home/maruthi/intelFPGA_lite/20.1/quartus/AES/TOP/../testbench/tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  tb

add wave *
view structure
view signals
run -all
