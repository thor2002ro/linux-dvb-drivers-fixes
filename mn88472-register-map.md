# MN88472 register reference

The driver uses 49 named register start addresses.
Definitions and settings live in
[`mn88472_priv.h`](upstream/linux/drivers/media/dvb-frontends/mn88472_priv.h);
[`mn88472.c`](upstream/linux/drivers/media/dvb-frontends/mn88472.c) uses them directly.
Bulk operations and indexed loops cover consecutive registers from the named start.
Bank 2 requires single-register transfers; existing transfer sizes are preserved.

Names were checked against the Panasonic-attributed
[MN88472.h](https://github.com/JasonFreeLab/HiSTBLinuxV100R005C00SPC050/blob/fd20f78ab02934e71474dbb1d933c6ec911b01c9/source/msp/drv/frontend/demod/mn88472/MN88472.h)
and [device functions](https://github.com/JasonFreeLab/HiSTBLinuxV100R005C00SPC050/blob/fd20f78ab02934e71474dbb1d933c6ec911b01c9/source/msp/drv/frontend/demod/mn88472/MN_DMD_device.c)
in the retained HiSilicon SDK mirror. This is not a complete programming manual.
Register definitions retain SDK symbols in comments for tracing their names.

Settings, acquisition thresholds, PLP and QAM selections, firmware control,
TS configuration, monitor masks, byte packing and fixed-point scaling are named.
Bandwidth coefficient byte strings remain unchanged calibration data.
IMPSET, FDAGCSET, TGAINSET and FECSET3 retain SDK names: their individual fields
are not established here. Recipe constants describe existing Linux settings;
they do not import different vendor tuning values.

Idle power control uses standby (PWDSET=0x3e). Probe only writes power
control; the sleep callback writes HIZSET2=0x30, HIZSET1=0x30, then PWDSET=0x3e.
Both use mn88472_power_sleep for the standby power write. Power and output
write failures are logged with their stage and errno without dynamic debug.
The vendor MN_DMD_driver.h power-mode enum documents standby as keeping I2C
and the clock running; sleep (0x3f) stops them and requires a hardware reset.
The Xbox bridge resets the demodulator during attachment, not normal wake,
and the frontend has no hardware-reset callback. Therefore 0x3f is unsuitable
for the existing probe/sleep and I2C-only wake sequence.
The experimental mode-2 sequence was withdrawn after a reported tuning failure.
Wake-up retains PWDSET=0x00, HIZSET1=0x00, HIZSET2=0x00 and the firmware-running
check. The reset requirement explains a source-level incompatibility; the exact
failed hardware operation still requires the new initialization diagnostics.

The linked Supra SDT-120 schematic documents another MN88472 board with an
MxL603 tuner and 20.48 MHz crystal; it does not establish HIZ bit-to-pin
assignments or justify changing the Xbox board's tuner/clock configuration.

| Bank index / I2C address | Register | Driver name | SDK symbol and meaning |
| --- | --- | --- | --- |
| 0 / 0x18 | `0x00` | `MN88472_REG_DVBT_MODE` | MDSET_T: DVB-T mode and guard selection |
| 0 / 0x18 | `0x01` | `MN88472_REG_DVBT_MODE_SEARCH` | MDASET_T: DVB-T automatic mode search |
| 0 / 0x18 | `0x07` | `MN88472_REG_DVBT_SEARCH_TIMEOUT_2` | STTOSET2_T: DVB-T search timeout setting 2 |
| 0 / 0x18 | `0x46` | `MN88472_REG_DVBT_FILTER_2` | FFILSET2_T: DVB-T filter setting 2 |
| 0 / 0x18 | `0x7f` | `MN88472_REG_DVBT_ACQUISITION_STATUS` | SSEQRD_T: DVB-T acquisition stage and errors |
| 0 / 0x18 | `0x89` | `MN88472_REG_DVBT_TPS` | TMCCD2_T: Decoded DVB-T TPS, first of three bytes |
| 0 / 0x18 | `0x9c` | `MN88472_REG_DVBT_CNR_HIGH` | CNRDU_T: DVB-T CNR monitor, high byte |
| 0 / 0x18 | `0xb4` | `MN88472_REG_AGC_REFERENCE` | AGCREF: AGC reference |
| 0 / 0x18 | `0xcd` | `MN88472_REG_IMPSET` | IMP setting; individual fields undocumented here |
| 0 / 0x18 | `0xd4` | `MN88472_REG_FDAGCSET` | FDAGC setting; individual fields undocumented here |
| 0 / 0x18 | `0xd6` | `MN88472_REG_TGAINSET` | T gain setting; individual fields undocumented here |
| 0 / 0x18 | `0xd9` | `MN88472_REG_TS_FIFO` | FIFOSET: TS FIFO and clock setting |
| 0 / 0x18 | `0xe1` | `MN88472_REG_PACKET_ERROR_HIGH` | PERRDU: Packet error count, followed by packet count |
| 0 / 0x18 | `0xf5` | `MN88472_REG_FIRMWARE_CONTROL` | PSEQSET: Program sequencer control |
| 0 / 0x18 | `0xf6` | `MN88472_REG_FIRMWARE_DATA` | PSEQPRG: Program sequencer data port (no address increment) |
| 0 / 0x18 | `0xf8` | `MN88472_REG_FIRMWARE_FLAGS` | PSEQFLG: Program sequencer flags |
| 1 / 0x1a | `0x00` | `MN88472_REG_DVBC_QAM_SEARCH` | CHSRCHSET_C: DVB-C QAM search selection |
| 1 / 0x1a | `0x83` | `MN88472_REG_DVBC_QAM_MONITOR` | SSEQMON1_C: Detected DVB-C QAM |
| 1 / 0x1a | `0x84` | `MN88472_REG_DVBC_ACQUISITION_STAGE` | SSEQMON2_C: DVB-C acquisition stage |
| 1 / 0x1a | `0x85` | `MN88472_REG_DVBC_ACQUISITION_STATUS` | STSMON_C: DVB-C acquisition errors |
| 1 / 0x1a | `0x86` | `MN88472_REG_DVBC_SYMBOL_RATE_HIGH` | RATERDU_C: DVB-C symbol-rate monitor, high byte |
| 1 / 0x1a | `0x89` | `MN88472_REG_DVBC_LOCK_STATUS` | DMDSTSMON1_C: DVB-C demodulator lock flags |
| 1 / 0x1a | `0xa1` | `MN88472_REG_DVBC_SIGNAL_NOISE` | CNMON1_C: DVB-C signal and noise monitors |
| 1 / 0x1a | `0xf6` | `MN88472_REG_FECSET3` | FEC setting 3 |
| 2 / 0x1c | `0x00` | `MN88472_REG_PLL_SETTING_1` | PLLSET1: PLL setting 1 |
| 2 / 0x1c | `0x01` | `MN88472_REG_PLL_SETTING_2` | PLLSET2: PLL setting 2 |
| 2 / 0x1c | `0x02` | `MN88472_REG_PLL_CONTROL` | PLLSET: PLL control |
| 2 / 0x1c | `0x03` | `MN88472_REG_DELIVERY_SYSTEM` | DTVSET: Delivery system selection |
| 2 / 0x1c | `0x04` | `MN88472_REG_BANDWIDTH` | SYSSET: Channel bandwidth selection |
| 2 / 0x1c | `0x05` | `MN88472_REG_POWER_CONTROL` | PWDSET: Power control |
| 2 / 0x1c | `0x08` | `MN88472_REG_TS_FORMAT` | TSSET1: TS output format |
| 2 / 0x1c | `0x0b` | `MN88472_REG_OUTPUT_HIZ_1` | HIZSET1: Output high-impedance setting 1 |
| 2 / 0x1c | `0x0c` | `MN88472_REG_OUTPUT_HIZ_2` | HIZSET2: Output high-impedance setting 2 |
| 2 / 0x1c | `0x10` | `MN88472_REG_IF_NCO_HIGH` | NCOFREQU: IF NCO frequency, high byte |
| 2 / 0x1c | `0x13` | `MN88472_REG_BANDWIDTH_COEFFICIENTS` | FADU: Bandwidth coefficients: FAD, FSFTX and FSFTY |
| 2 / 0x1c | `0x2b` | `MN88472_REG_DVBT2_WIDE_AFC_3` | WAFCSET3: Wide AFC setting 3 |
| 2 / 0x1c | `0x30` | `MN88472_REG_DVBT2_FEC_PLP_MODE` | FECSET1: FEC and PLP selection mode |
| 2 / 0x1c | `0x32` | `MN88472_REG_DVBT2_PLP_ID` | PLPID: PLP identifier or ordinal |
| 2 / 0x1c | `0x4f` | `MN88472_REG_DVBT2_DETECTION_2` | DETSET2: Detection setting 2 |
| 2 / 0x1c | `0x8e` | `MN88472_REG_AGC_HIGH` | AGCRDU: AGC monitor, high byte |
| 2 / 0x1c | `0x92` | `MN88472_REG_DVBT2_ACQUISITION_STATUS` | SSEQFLG: DVB-T2 acquisition stage and flags |
| 2 / 0x1c | `0x93` | `MN88472_REG_DVBT2_FFT_MODE` | SSEQRD1: DVB-T2 FFT mode readback |
| 2 / 0x1c | `0xbc` | `MN88472_REG_DVBT2_CNR_FLAGS` | CNFLG: DVB-T2 CNR flags, followed by CNR value |
| 2 / 0x1c | `0xc4` | `MN88472_REG_DVBT2_L1_SELECTOR` | TPDSET1: L1 monitor selector 1 |
| 2 / 0x1c | `0xc5` | `MN88472_REG_DVBT2_L1_PAGE` | TPDSET2: L1 monitor selector 2 |
| 2 / 0x1c | `0xc7` | `MN88472_REG_DVBT2_L1_DATA_2` | TPD2: L1 monitor data 2 |
| 2 / 0x1c | `0xc8` | `MN88472_REG_DVBT2_L1_DATA_3` | TPD3: L1 monitor data 3 |
| 2 / 0x1c | `0xf8` | `MN88472_REG_RESET_CONTROL` | RSTSET1: Demodulator reset control |
| 2 / 0x1c | `0xff` | `MN88472_REG_CHIP_ID` | CHIPRD: Chip identifier |

Source SHA-256: `d8fae5733d8abd33dfbfd7e182fe89730079738550cd0653135ca4963849a93e`.
