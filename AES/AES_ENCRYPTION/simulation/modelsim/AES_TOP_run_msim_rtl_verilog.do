transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES_ENCRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES_ENCRYPTION/code/AES_TOP.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES_ENCRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES_ENCRYPTION/code/sbox.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES_ENCRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES_ENCRYPTION/code/keyExpansion.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES_ENCRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES_ENCRYPTION/code/mixColumns.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES_ENCRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES_ENCRYPTION/code/shiftRows.v}
vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES_ENCRYPTION/code {/home/maruthi/intelFPGA_lite/20.1/quartus/AES_ENCRYPTION/code/subBytes.v}

vlog -vlog01compat -work work +incdir+/home/maruthi/intelFPGA_lite/20.1/quartus/AES_ENCRYPTION/testbench {/home/maruthi/intelFPGA_lite/20.1/quartus/AES_ENCRYPTION/testbench/tb_aes_en.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  tb_aes_en

add wave *
view structure
view signals
run -all
