.TH THINKFAN.CONF 5 "December 2021" "thinkfan @THINKFAN_VERSION@"
.SH NAME
thinkfan.conf \- YAML-formatted config for
.BR thinkfan (1)



.SH DESCRIPTION

YAML is a very powerful, yet concise notation for structured data.
Its full specification is available at https://yaml.org/spec/1.2/spec.html.
Thinkfan uses only a small subset of the full YAML syntax, so it may be helpful,
but not strictly necessary for users to take a look at the spec.

The most important thing to note is that indentation is syntactically relevant.
In particular, tabs should not be mixed with spaces.
We recommend using two spaces for indentation, like it is shown below.

The thinkfan config has three main sections:

.TP 11m
.B sensors:
Where temperatures should be read from. All
.BR hwmon -style
drivers are supported, as well as
.BR /proc/acpi/ibm/thermal ,
and, depending on the compile-time options,
.B libatasmart
(to read temperatures directly from hard disks) and
.B NVML
(via the proprietary nvidia driver).

.TP
.B fans:
Which fans should be used (currently only one allowed).
Support for multiple fans is currently in development and planned for a future
release.
Both
.BR hwmon -style
PWM controls and
.B /proc/acpi/ibm/fan
can be used.

.TP
.B levels:
Maps temperatures to fan speeds.
A \*(lqsimple mapping\*(rq just specifies one temperature as the lower and
upper bound (respectively) for a given fan speed.
In a \*(lqdetailed mapping\*(rq, the upper and lower bounds are specified for
each driver/sensor configured under
.BR sensors: .
This mode should be used when thinkfan is monitoring multiple devices that can
tolerate different amounts of heat.

.PP
Under each of these sections, there must be a list of key-value maps, each of
which configures a sensor driver, fan driver or fan speed mapping.



.SH SENSOR & FAN DRIVERS

For thinkfan to work, it first needs to know which temperature sensor drivers
and which fan drivers it should use.
The mapping between temperature readings and fan speeds is specified in a
separate config section (see the
.B FAN SPEEDS
section below).


.SS Sensor Syntax

The entries under the
.B sensors:
section can specify
.BR hwmon,
.BR thinkpad_acpi,
.BR NVML
or
.BR atasmart
drivers, where the latter two must be enabled at compile-time.
There can be any number (greater than zero) and combination of
.BR hwmon ,
.BR tpacpi ,
.BR nvml
and
.BR atasmart
entries.
However there may be at most one instance of the
.BR tpacpi
entry.

.nf
.B  "sensors:"
.BI "  \- hwmon: " hwmon-path
.BI "    name: " hwmon-name
.BI "    indices: " index-list
.BI "    correction: " correction-list
.BI "    optional: " bool-allow-errors

.B  "  \- tpacpi: /proc/acpi/ibm/thermal"
.BI "    indices: " index-list
.BI "    correction: " correction-list
.BI "    optional: " bool-allow-errors

.BI "  \- nvml: " nvml-bus-id
.BI "    correction: " correction-list
.BI "    optional: " bool-allow-errors

.BI "  \- atasmart: " disk-device-file
.BI "    correction: " correction-list
.BI "    optional: " bool-allow-errors

.BR "  \- " ...
.fi


.SS Fan Syntax

Currently, thinkfan supports only one fan, so there can be only one entry in the
list.
Support for multiple fans is currently in development and planned for a future
release.
The fan is either an
.B hwmon
fan:

.nf
.B  "fans:"
.BI "  \- hwmon: " hwmon-path
.BI "    name: " hwmon-name
.BI "    indices: " index-list
.fi

or a
.B tpacpi
fan:

.nf
.B  "fans:"
.B "  \- tpacpi: /proc/acpi/ibm/fan"
.fi


.SS Values

.TP 12m
.I hwmon-path
There are three ways of specifying hwmon fans or sensors:

.TP
\h'8m'1)
A full path of a \*(lqtemp*_input\*(rq or \*(lqpwm*\*(rq file, like
\*(lq/sys/class/hwmon/hwmon0/pwm1\*(rq or
\*(lq/sys/class/hwmon/hwmon0/temp1_input\*(rq.
In this case, the \*(lq\c
.BI indices: " index-list"\c
\*(rq and \*(lq\c
.BI name: " hwmon-name"\c
\*(rq entries are unnecessary since the path uniquely identifies a specific fan or
sensor.

Note that this method may lead to problems when the load order of the drivers
changes across bootups, because in the \*(lqhwmon\fIX\fR\*(rq folder name, the
.I X
actually corresponds to the load order.
Use method 2) or 3) to avoid this problem.

.TP
\h'8m'2)
A directory that contains a specific hwmon driver, for example
\*(lq/sys/devices/platform/nct6775.2592\*(rq.
Note that this path does not contain the load-order dependent
\*(lqhwmon\fIX\fR\*(rq folder.
As long as it contains only a single hwmon driver/interface it is sufficient to
specify the
\*(lq\c
.BI indices: " index-list"\c
\*(rq
entry to tell thinkfan which specific sensors to use from that interface.
The
\*(lq\c
.BI name: " hwmon-name"\c
\*(rq
entry is unnecessary.


.TP
\h'8m'3)
A directory that contains multiple or all of the hwmon drivers, for example
\*(lq/sys/class/hwmon\*(rq.
Here, both the \*(lq\c
.BI name: " hwmon-name"\c
\*(rq and \*(lq\c
.BI indices: " index-list"\c
\*(rq entries are required to tell thinkfan which interface to select below that
path, and which sensors or which fan to use from that interface.

.TP
.I hwmon-name
The name of a hwmon interface, typically found in a file called \*(lqname\*(rq.
This has to be specified if
.I hwmon-path
is a base path that contains multiple hwmons.
This method of specifying sensors is particularly useful if the full path to a
particular hwmon keeps changing between bootups, e.g. due to changing load order
of the driver modules.

.TP
.I index-list
A YAML list
.BI "[ "  X1  ", "  X2  ", " "\fR...\fB ]"
that specifies which sensors, resp. which fan to use from a given
interface.
Both
.B /proc/acpi/ibm/thermal
and also many hwmon interfaces contain multiple sensors, and not
all of them may be relevant for fan control.

.TP
\h'9m'\(bu
For
.B hwmon
entries, this is required if
.I hwmon-path
does not refer directly to a single \*(lqtemp\fIXi\fR_input\*(rq file, but to a folder
that contains one or more of them.
In this case,
.I index-list
specifies the
.I Xi
for the \*(lqtemp\fIXi\fR_input\*(rq files that should be used.
A hwmon interface may also contain multiple PWM controls for fans, so in that case,
.I index-list
must contain exactly one entry.

.TP
\h'9m'\(bu
For
.B tpacpi
sensors, this entry is optional.
If it is omitted, all temperatures found in
.B /proc/acpi/ibm/thermal
will be used.

.TP
.I nvml-bus-id
NOTE: only available if thinkfan was compiled with USE_NVML enabled.

The PCI bus ID of an nVidia graphics card that is run with the proprietary
nVidia driver. Can be obtained with e.g. \*(lqlspci | grep \-i vga\*(rq.
Usually, nVidia cards will use the open source
.B nouveau
driver, which should support hwmon sensors instead.

.TP
.I disk-device-file
NOTE: only available if thinkfan was compiled with USE_ATASMART enabled.

Full path to a device file for a hard disk that supports S.M.A.R.T.
See also the
.B \-d
option in
.BR thinkfan (1)
that prevents thinkfan from waking up sleeping (mechanical) disks to read their
temperature.

.TP
.IR correction-list " (always optional)"
A YAML list that specifies temperature offsets for each sensor in use by the
given driver. Use this if you want to use the \*(lqsimple\*(rq level syntax,
but need to compensate for devices with a lower heat tolerance.
Note however that the detailed level syntax is usually the better (i.e. more
fine-grained) choice.

.TP
.IR bool-allow-errors " (always optional, \fBfalse\fR by default)"
A truth value
.RB ( yes / no / true / false )
that specifies whether thinkfan should accept errors when reading from this
sensor.
Normally, thinkfan will exit with an error message if reading the temperature
from any configured sensor fails.
Marking a sensor as optional may be useful for removable hardware or devices
that may get switched off entirely to save power.



.SH FAN SPEEDS

The
.B levels:
section specifies a list of fan speeds with associated lower and upper
temperature bounds.
If temperature(s) drop below the lower bound, thinkfan switches to the previous
level, and if the upper bound is reached, thinkfan switches to the next level.

.SS Simple Syntax
In the simplified form, only one temperature is specified as an upper/lower
limit for a given fan speed.
In that case, the
.I lower-bound
and
.I upper-bound
are compared only to the highest temperature found among all configured sensors.
All other temperatures are ignored.
This mode is suitable for small systems (like laptops) where there is only one
device (e.g. the CPU) whose temperature needs to be controlled, or where the
required fan behaviour is similar enough for all heat-generating devices.

.nf
.B "levels:"
.BI "  \- [ " fan-speed ", " lower-bound ", " upper-bound " ]"
.BR "  \- " ...
.fi


.SS Detailed Syntax
This mode is suitable for more complex systems, with devices that have
different temperature ratings.
For example, many modern CPUs and GPUs can deal with temperatures above
80\[char176]C on a daily basis, whereas a hard disk will die quickly if it
reaches such temperatures.
In detailed mode, upper and lower temperature limits are specified for each
sensor individually:

.nf
.B  "levels:"
.BI "  \- speed: " fan-speed
.BI "    lower_limit: [ " l1 ", " l2 ", " "\fR..." " ]"
.BI "    upper_limit: [ " u1 ", " u2 ", " "\fR..." " ]"
.BR "  \- " ...
.fi


.SS Values

.TP 12m
.I fan-speed
The possible speed values are different depending on which fan driver is used.

For a
.B hwmon
fan,
.I fan-speed
is a numeric value ranging from
.B 0
to
.BR 255 ,
corresponding to the PWM values accepted by the various kernel drivers.

For a
.B tpacpi
fan on Lenovo/IBM ThinkPads and some other Lenovo laptops (see \fBSENSORS & FAN
DRIVERS\fR above), numeric values and strings can be used.
The numeric values range from 0 to 7.
The string values take the form \fB"level \fIlvl-id\fB"\fR, where
.I lvl-id
may be a value from
.BR 0 " to " 7 ,
.BR auto ,
.B full-speed
or
.BR disengaged .
The numeric values
.BR 0 " to " 7
correspond to the regular fan speeds used by the firmware, although many
firmwares don't even use level \fB7\fR.
The value \fB"level auto"\fR gives control back to the firmware, which may be
useful if the fan behavior only needs to be changed for certain specific
temperature ranges (usually at the high and low end of the range).
The values \fB"level full-speed"\fR and \fB"level disengaged"\fR take the fan
speed control away from the firmware, causing the fan to slowly ramp up to an
absolute maximum that can be achieved within electrical limits.
Note that this will run the fan out of specification and cause increased wear,
though it may be helpful to combat thermal throttling.

.TP
.IB l1 ", " l2 ", " \fR...
.TP
.IB u1 ", " u2 ", " \fR...
The lower and upper limits refer to the sensors in the same order in which they
were found when processing the
.B sensors:
section (see
.B SENSOR & FAN DRIVERS
above).
For the first level entry, the
.B lower_limit
may be omitted, and for the last one, the
.B upper_limit
may be omitted.
For all levels in between, the lower limits must overlap with the upper limits
of the previous level, to make sure the entire temperature range is covered and
that there is some hysteresis between speed levels.


.SH SEE ALSO
.nf
The thinkfan manpage:
.BR thinkfan (1)

Example configs shipped with the source distribution, also available at:
.hy 0
https://github.com/vmatare/thinkfan/tree/master/examples

The Linux hwmon user interface documentation:
https://www.kernel.org/doc/html/latest/hwmon/sysfs\-interface.html

The thinkpad_acpi interface documentation:
https://www.kernel.org/doc/html/latest/admin\-guide/laptops/thinkpad\-acpi.html


.SH BUGS

.hy 0
.nf
Report bugs on the github issue tracker:
https://github.com/vmatare/thinkfan/issues

