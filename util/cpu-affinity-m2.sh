#!/bin/sh

# Script to tune the CPU core usage on the RK3588(S2)

# Power saving from lowering the 4xA55 CPU cluster clock is quite small.
# Leaving it at max performance can help with desktop responsiveness.
echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor

# Use ondemand scheduler on big cores.
echo ondemand > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor
echo ondemand > /sys/devices/system/cpu/cpufreq/policy6/scaling_governor

AFFNITIY_AWK=""

irq_affinity() {
	AFFINITY_AWK="$AFFINITY_AWK /$1/ {print \"echo $2 > /proc/irq/\" int(\$1) \"/smp_affinity_list\"}"
}

# Many interrupts are handled by by default only on CPU0.
# Spreading devices with heavier usage to other cores gives better performance.
# Here the A55 cores are used to leave the big cores idle on background activity.
irq_affinity dma-controller 1
irq_affinity xhci-hcd:usb 1
irq_affinity vop 2
irq_affinity end0 2
irq_affinity fd880000.i2c 3

# OpenGL performance seems to be better with panthor-job on an A76 core.
irq_affinity panthor-job 6

# Bulk of USB-3/USB-C processing seems to happen with dwc3 interrupts, use another A76 core for that
irq_affinity dwc3 7

# Apply the IRQ CPU affinity rules
awk -F: "$AFFINITY_AWK" < /proc/interrupts | sh

# Tune the ondemand scheduler respond to the io activity, and faster. Somewhat surprisingly
# Quake3 also seems to be smoother with tuned ondemand scheduler compared to schedutil.
if [ -d /sys/devices/system/cpu/cpufreq/ondemand ]; then
	echo 1 > /sys/devices/system/cpu/cpufreq/ondemand/io_is_busy
	echo 10 > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor
	echo 25 > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold
	echo 200000 > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate
fi
