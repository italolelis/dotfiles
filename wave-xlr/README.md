# wave-xlr (Omarchy only)

Elgato Wave XLR glue: `wave-xlr-volume` (volume keys → the device's headphone level)
and a WirePlumber soft-mixer rule. OpenXLR itself comes from the Archfile; `install.sh`
enables its daemon and bar plugin.

- **The hardware mixer is half broken.** Reading its `Mic` control fails
  (`broken mixer GET_CUR` in `dmesg`), so the WirePlumber rule keeps PipeWire on a soft
  mixer, and `wave-xlr-volume` writes only the `PCM` control (the headphone level).
- The mic-goes-silent bug is fixed by OpenXLR's packaged
  `52-openxlr-mk1-capture-hold.conf`, not by anything here.
- The rule matches any Wave XLR by name pattern on purpose: a unit's serial number does
  not belong in this public repo.
