vlog -sv bus_decoder.v
vlog -sv dual_ram.v
vlog -sv gpio_module.v 
vlog -sv tb_gpio.v 
vsim tb_gpio.v 