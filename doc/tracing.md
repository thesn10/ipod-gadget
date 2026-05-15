# Tracing & Debugging

## 1. pr_info / pr_err — always visible

```bash
dmesg -w
journalctl -k -f
```

Prefixed with `ipod-gadget-hid:` / `ipod-gadget:` / `ipod-gadget-audio:` per module.

---

## 2. trace_printk — hot-path tracing

Instrumented in `ipod_hid_setup`, `ipod_hid_recv_complete`, `poll`, etc.

```bash
# live (blocking)
sudo cat /sys/kernel/debug/tracing/trace_pipe

# snapshot
sudo cat /sys/kernel/debug/tracing/trace
```

Active as soon as the module is loaded. The NOTICE warning in dmesg on load is expected.

---

## 3. DBG() — dynamic debug (off by default)

`DBG()` maps to `dev_dbg()` — filtered until explicitly enabled:

```bash
# this module only
echo "module g_ipod +p" | sudo tee /sys/kernel/debug/dynamic_debug/control

# single file
echo "file ipod_hid.c +p" | sudo tee /sys/kernel/debug/dynamic_debug/control

# disable again
echo "module g_ipod -p" | sudo tee /sys/kernel/debug/dynamic_debug/control
```

Output appears in `dmesg -w`.

---

## 4. libcomposite dynamic debug — USB control requests from host

Shows GET_DESCRIPTOR, SET_CONFIGURATION, SET_INTERFACE — what the radio does at USB level before iAP begins.

```bash
echo "module libcomposite +p" | sudo tee /sys/kernel/debug/dynamic_debug/control
# optional
echo "module dwc2 +p"         | sudo tee /sys/kernel/debug/dynamic_debug/control
```

Example output:
```
g_ipod gadget.0: control req: 80.06 v0100 i0000 l18   # GET_DEVICE_DESCRIPTOR
g_ipod gadget.0: control req: 80.06 v0200 i0000 l255  # GET_CONFIG_DESCRIPTOR
g_ipod gadget.0: control req: 00.09 v0002 i0000 l0    # SET_CONFIGURATION 2
g_ipod gadget.0: control req: 01.0b v0001 i0001 l0    # SET_INTERFACE 1 alt 1
```

---

## 5. USB gadget ftrace events

```bash
# list available events
ls /sys/kernel/debug/tracing/events/gadget/

# enable all
echo 1 | sudo tee /sys/kernel/debug/tracing/events/gadget/enable

sudo cat /sys/kernel/debug/tracing/trace_pipe

# disable
echo 0 | sudo tee /sys/kernel/debug/tracing/events/gadget/enable
```

---

## Enable everything at once

```bash
echo "module g_ipod +p"       | sudo tee /sys/kernel/debug/dynamic_debug/control
echo "module libcomposite +p" | sudo tee /sys/kernel/debug/dynamic_debug/control
echo "module dwc2 +p"         | sudo tee /sys/kernel/debug/dynamic_debug/control
echo 1 | sudo tee /sys/kernel/debug/tracing/events/gadget/enable
dmesg -w &
sudo cat /sys/kernel/debug/tracing/trace_pipe
```
