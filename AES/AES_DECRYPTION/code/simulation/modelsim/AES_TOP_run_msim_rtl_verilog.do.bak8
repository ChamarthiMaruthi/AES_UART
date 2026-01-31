transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES_DECRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES_DECRYPTION/code/AES_TOP.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES_DECRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES_DECRYPTION/code/keyexpanison.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES_DECRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES_DECRYPTION/code/inverseSbox.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES_DECRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES_DECRYPTION/code/inverseShiftrows.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES_DECRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES_DECRYPTION/code/inverseSubBytes.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES_DECRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES_DECRYPTION/code/invMixColumns.v}

vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES_DECRYPTION/code/../testbench {/home/maruthi/intelFPGA_lite/20.1/quartus/AES_DECRYPTION/code/../testbench/tb_de_aes.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  tb_de_aes

add wave *
view structure
view signals
run -all
