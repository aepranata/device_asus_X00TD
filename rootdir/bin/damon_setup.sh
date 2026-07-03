#!/vendor/bin/sh
#
# damon_setup.sh - Configure DAMON (paddr mode) as a proactive complement
# to MGLRU on X00TD. Run once at boot via init.damon.rc.
#
# Every write is guarded by an existence check on the sysfs node before
# writing to it, so this script degrades safely (skips silently, doesn't
# abort or spam logs) on any build where CONFIG_DAMON/CONFIG_DAMON_PADDR/
# CONFIG_DAMON_SYSFS ended up disabled for some reason, instead of
# breaking boot.

KDROOT=/sys/kernel/mm/damon/admin/kdamonds
KD=$KDROOT/0

# [bugfix] This was originally named log() - naming it the same as the
# external `log` command it calls inside its own body makes the shell
# resolve that inner call back to this same function (shell function
# names shadow $PATH lookups), causing infinite self-recursion and a
# stack-overflow segfault. Confirmed by testing: "Segmentation fault"
# when running the script. Renamed to avoid the collision.
log_msg() {
	log -t damon_setup "$1"
}

w() {
	# w <path> <value> - write only if the node exists
	if [ -e "$1" ]; then
		echo "$2" > "$1"
	else
		log_msg "skip (missing): $1"
	fi
}

if [ ! -d "$KDROOT" ]; then
	log_msg "DAMON sysfs not found at $KDROOT, nothing to do"
	exit 0
fi

log_msg "configuring DAMON paddr scheme"

# --- kdamond count: this dynamically creates kdamonds/0/ ---
# (must happen before anything under $KD is touched, since $KD itself
# doesn't exist until this write lands)
w "$KDROOT/nr_kdamonds" 1

if [ ! -d "$KD" ]; then
	log_msg "kdamonds/0 did not appear after nr_kdamonds write, aborting"
	exit 0
fi

# --- context count / mode ---
w "$KD/contexts/nr_contexts" 1
CTX="$KD/contexts/0"
w "$CTX/operations" paddr

# --- monitoring intervals ---
w "$CTX/monitoring_attrs/intervals/sample_us" 5000
w "$CTX/monitoring_attrs/intervals/aggr_us" 200000
w "$CTX/monitoring_attrs/intervals/update_us" 1000000

# --- region count bounds ---
w "$CTX/monitoring_attrs/nr_regions/min" 10
w "$CTX/monitoring_attrs/nr_regions/max" 500

# --- target (paddr mode: single whole-memory target) ---
w "$CTX/targets/nr_targets" 1
TGT="$CTX/targets/0"

# paddr does NOT auto-populate monitoring regions like vaddr does -
# it must be set manually, or DAMON has zero region to ever scan.
#
# [bugfix] Originally used a single region 0 -> ULONG_MAX as a lazy
# "whole address space" placeholder. Confirmed by device testing: this
# overflows/degenerates the region-splitting math on this kernel's
# DAMON backport, so nr_tried/sz_tried stay 0 forever regardless of
# every other setting (watermarks, quotas, access_pattern all tested
# individually - none of those were the actual cause). Parsing the
# real System RAM ranges from /proc/iomem and using those as separate
# initial regions instead fixed it (confirmed: nr_tried=9, sz_tried
# ~90MB on first run).
RAM_RANGES=$(grep "System RAM" /proc/iomem | sed 's/ *:.*//')
NR=$(echo "$RAM_RANGES" | grep -c .)

if [ "$NR" -gt 0 ]; then
	w "$TGT/regions/nr_regions" "$NR"
	i=0
	echo "$RAM_RANGES" | while IFS='-' read -r start_hex end_hex; do
		start_dec=$(( 0x$start_hex ))
		end_dec=$(( 0x$end_hex + 1 ))
		w "$TGT/regions/$i/start" "$start_dec"
		w "$TGT/regions/$i/end" "$end_dec"
		i=$((i + 1))
	done
else
	log_msg "no System RAM ranges found in /proc/iomem, DAMON will have nothing to monitor"
fi

# --- scheme: DAMOS_PAGEOUT for genuinely cold regions ---
w "$CTX/schemes/nr_schemes" 1
SCH="$CTX/schemes/0"

w "$SCH/action" pageout

w "$SCH/access_pattern/sz/min" 4096
w "$SCH/access_pattern/sz/max" 18446744073709551615

w "$SCH/access_pattern/nr_accesses/min" 0
w "$SCH/access_pattern/nr_accesses/max" 0
w "$SCH/access_pattern/age/min" 15
w "$SCH/access_pattern/age/max" 4294900000

w "$SCH/quotas/ms" 100
w "$SCH/quotas/bytes" 10485760
w "$SCH/quotas/reset_interval_ms" 1000

w "$SCH/quotas/weights/sz_permil" 0
w "$SCH/quotas/weights/nr_accesses_permil" 0
w "$SCH/quotas/weights/age_permil" 1000

w "$SCH/watermarks/metric" free_mem_rate
w "$SCH/watermarks/interval_us" 5000000
w "$SCH/watermarks/high" 700
w "$SCH/watermarks/mid" 500
w "$SCH/watermarks/low" 200

# --- go ---
w "$KD/state" on

log_msg "DAMON paddr scheme active"
