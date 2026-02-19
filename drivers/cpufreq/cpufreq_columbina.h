/*
 * Header file for CPUFreq columbina (ondemand based) governor and related code.
 *
 * Copyright (C) 2016, Intel Corporation
 * Author: Rafael J. Wysocki <rafael.j.wysocki@intel.com>
 * Modifyed: Anomaly-arc <miquu.official@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include "cpufreq_governor.h"

struct moon_policy_dbs_info {
	struct policy_dbs_info policy_dbs;
	unsigned int freq_lo;
	unsigned int freq_lo_delay_us;
	unsigned int freq_hi_delay_us;
	unsigned int sample_type:1;
};

static inline struct moon_policy_dbs_info *to_dbs_info(struct policy_dbs_info *policy_dbs)
{
	return container_of(policy_dbs, struct moon_policy_dbs_info, policy_dbs);
}

struct moon_ops {
	unsigned int (*powersave_bias_target)(struct cpufreq_policy *,
			unsigned int, unsigned int);
};

struct moon_dbs_tuners {
    unsigned int powersave_bias;
    unsigned int io_is_busy;
    unsigned int columbina_mode;
	unsigned int down_differential;
	unsigned int dynamic_threshold_enable;
};