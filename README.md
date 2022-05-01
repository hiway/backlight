# backlightd

Nicer display backlight (screen brightness) controls for FreeBSD

## Install

Download latest release:

https://github.com/hiway/backlightd/releases/tag/v0.1.0

Install

```console
pkg install backlightd-VERSION.pkg
```

Load acpi_ibm kernel module:

```console
kldload acpi_ibm
sysrc kld_list+=acpi_ibm
```

Initialise, enable and start the service

```console
service backlightd init
service backlightd enable
service backlightd start
```

Try pressing the brightness keys (Fn+F5 / Fn+F6), 
your screen brightness should fade 
between a handful presets.
