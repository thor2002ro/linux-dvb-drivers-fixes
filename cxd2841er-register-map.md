# CXD2841ER register reference

Readable names for every register address accessed by this checkout's
[cxd2841er.c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c).
The private header [cxd2841er_priv.h](upstream/linux/drivers/media/dvb-frontends/cxd2841er_priv.h)
defines these names with the `CXD2841ER_REG_` prefix; the driver uses them
for register-address arguments. Names describe this driver's use or matching
Sony SDK fields; vendor acronyms are retained without guessed expansions. `CXD2841ER_BANK_`, `CXD2841ER_SET_`, and `CXD2841ER_MASK_`
name bank pages, scalar write settings, and masked-write fields in the driver.
Settings with `PRESET` or `UNKNOWN` in their names retain values whose precise
hardware meaning is not explained by this source. Multi-byte calibration tables
and calculated payload bytes retain their numeric contents.
The common DVB-T/T2 status and AGC helpers use `DVBT_T2_SYNC_STATUS` and
`DVBT_T2_IF_AGC_GAIN` for the matching offsets in banks `10` and `20`.

## How to read the map

A register is identified by **I2C target + bank + byte address**. For example,
`SLV-T / 00 / C3` stops TS output; `SLV-T / AB / C3-C4` is a satellite setup
block. Identical byte addresses in different banks must not be merged.

- `SLV-T` and `SLV-X` use `priv->i2c_addr_slvt` and `priv->i2c_addr_slvx`.
  The 7-bit addresses are `cfg->i2c_addr >> 1` for SLV-T and
  `(cfg->i2c_addr + 4) >> 1` for SLV-X;
  `I2C_SLVT=1` and `I2C_SLVX=0` are target selectors, not bus addresses.
- All bank/address numbers are hexadecimal. Inclusive address ranges cover
  **every transferred byte**, including bytes not decoded by the driver.
  A range is one block name; it does not assert that all bytes share a field.
- `R`, `W`, and `M` describe what this driver does: read, write, or masked
  update. They do **not** declare the hardware's access permissions.
  `M` uses `(old & ~mask) | (data & mask)`; with mask `FF`, it writes directly.
- Field meanings come from this source's comments, calculations, callers and
  matched Sony SDK tables. T/T2/C names use the 2013 avlogic/AVL6862 Sony SDK;
  ISDB names use the later CXD285X source and matching CXD2856 decompiles.
  Names ending in `UNKNOWN` identify setup bytes whose precise hardware
  purpose is not explained. Other entries explicitly qualify incomplete
  field meanings. Later-chip correspondences do not establish identical silicon
  behavior or justify replacing setup values; the two partial matches stay qualified.
- Source links show up to two representative using functions per entry.
  The `cxd2841er_` prefix is omitted from link labels for readability.
  Bank selection and the two helpers without bank selection are listed first.

## Quick orientation

| Target / bank | Uses in this driver |
| --- | --- |
| SLV-X / 00 | Reset, oscillator/crystal, ADC disable, demodulator mode, chip ID |
| SLV-T / 00 | Clocks, ADCs, output pins, TS format/output, chip ID, tune reset |
| SLV-T / 10-1E | Shared terrestrial/cable setup, DVB-T monitoring, ISDB-T setup |
| SLV-T / 20-2E | DVB-T2 monitoring, timing, PLP/profile and setup |
| SLV-T / 40, 48, 49 | DVB-C monitoring and setup |
| SLV-T / 5E | DVB-T2 24 MHz setup block |
| SLV-T / 60, 63 | ISDB-T monitoring and setup |
| SLV-T / A0-AE, B2 | DVB-S/S2 monitoring and setup |
| SLV-T / BB | DiSEqC command, mini-burst and continuous tone |

These ranges are orientation only: the detailed tables contain only banks
and registers actually accessed. Advertising C2/ISDB-S chip capabilities
does not imply that this file implements separate register paths for them.

## Bank-context and interpretation notes

1. **Bandwidth switch cases are alternative paths.** Each DVB-T2 case starts
   with bank `20` for the nominal-rate write, then selects `27` and `10`.
   Each DVB-T/ISDB-T bandwidth case starts with bank `10`. Reading the file
   as one linear sequence would incorrectly put later cases in `10`, `17`
   or `15` based on the previous case's final bank.
2. **Carrier-offset helpers inherit a selected bank.** DVB-T/T2 offset reads
   at `4C-4F` follow `read_status_t_t2`, which selects `10` or `20` after the
   caller has checked the delivery system. The common status and AGC helpers
   therefore appear in both bank tables.
3. **ISDB-T comments are not enough to establish the bank.** In
   `sleep_tc_to_active_i`,
   bank `00` remains selected for the ASCOT-labelled `A5` update and the
   FEC-labelled `30`/`31` updates. They are mapped at their actual addresses,
   without claiming they have the bank-`10`/`18` functions suggested by those
   comments. The `data24m`/`data24m2` writes are also unconditional here.
4. **Masked data is not necessarily the value written.** The pre-RS BER
   setup at `18:36` passes data `40` with mask `07`, so bits 2:0 are cleared.
   Similarly, ISDB-T `10:E2` changes only bit 7 and `10:F2` only bit 4.
   This reference records existing code; it does not correct these calls.
5. **ADC and auto-detection numbering is inconsistent in comments.**
   Names retain address suffixes rather than inventing ADC identities or
   swapping the `00:2D` and `AE:30` auto-detection settings.
6. **Nominal-rate width is not inferred from an inconsistent comment.**
   Tables say `[37:0]`, but DVB-T2 1.712 MHz first bytes include `58`/`68`.
   The map describes the full five-byte transfer without discarding bits.
7. **No bank selected does not prove bank independence.** Freeze/unfreeze
   use SLV-T `01` without selecting a bank. The tuner gate uses SLV-X `08`
   without selecting a bank. These are listed separately, exactly as used.

## Source snapshot and coverage

- Source SHA-256: `f42e60b6563a0420b5ef63d193c9a19747eb080b8f34909d53c984eb24898e7b`.
- Inventory: **534 direct register-access call sites**, **167 target/bank/start-address entries**, **287 distinct byte locations** after expanding block transfers and both conditional banks.
- The two bank selectors and the two helpers without bank selection count as four special entries/byte locations.
- Shared low-level helpers forward caller-provided `addr`/`reg` and add no fixed register addresses; CNR lookup values and payload bytes are not register addresses.
- Coverage was checked against every direct `read_reg(s)`, `write_reg(s)` and `set_reg_bits` call, with explicit checks for alternative bandwidth cases, inherited status banks, both chip-ID targets and the 12-byte DiSEqC block.
- This is a source reference, not a full silicon register specification or a hardware test. Recheck bank context and links if the source changes.


## Bank selectors and helpers without bank selection

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `SLV-X / 00` | W | `BANK_SELECT` | Selects the SLV-X register bank independently of SLV-T. This driver selects only bank 0x00 on SLV-X. | [sleep_s_to_active_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L456), [active_s_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L703); 15 functions total |
| `SLV-X / 08` | M | `TUNER_I2C_GATE` | Bit 0: 1 opens the tuner I2C gate, 0 closes it. The helper does not select a bank; other SLV-X accesses in this driver select bank 0x00. Bank independence is not established by this source. | [i2c_gate_ctrl](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L6294) |
| `SLV-T / 00` | W | `BANK_SELECT` | Selects the SLV-T register bank. The value is a bank number, not a register address. | [dvbs2_set_symbol_rate](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L416), [sleep_s_to_active_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L467); 54 functions total |
| `SLV-T / 01` | W | `MONITOR_FREEZE` | Write 1 to hold a coherent monitor snapshot; write 0 to release it. Helpers do not select a bank. | [freeze_regs](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2612), [unfreeze_regs](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2622) |

## SLV-X, bank 00

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `02` | W | `CLEAR_DEMOD_REGISTERS` | Write 0 during shutdown-to-sleep initialization, then wait 3-5 ms. | [shutdown_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1285), [shutdown_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1419) |
| `10` | W | `DEMOD_RESET_HOLD` | Write 1 to assert demodulator software reset and 0 to release it during initialization. | [shutdown_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1298), [shutdown_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1432) |
| `12` | W | `DEMOD_FREQUENCY_SELECT` | Written 0 for the crystal configurations shown in the initialization code. Full encoding is not documented. | [shutdown_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1314), [shutdown_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1450) |
| `13` | W | `ADC_CLOCK_MODE` | Written 0 during terrestrial/cable initialization. | [shutdown_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1438) |
| `14` | W | `CRYSTAL_FREQUENCY_SELECT` | Values used: 0=20.5 MHz, 3=24 MHz, 1=41 MHz. | [shutdown_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1306), [shutdown_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1466) |
| `15` | W | `OSCILLATOR_DISABLE` | Written 1 when entering shutdown. | [sleep_s_to_shutdown](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L813), [sleep_tc_to_shutdown](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L845) |
| `17` | W | `DEMOD_MODE` | Values used: 0x01=shutdown, 0x0a=DVB-S, 0x0b=DVB-S2, 0x01=DVB-T activation, 0x02=DVB-T2, 0x04=DVB-C, 0x06=ISDB-T. Meaning depends on the surrounding power/reset sequence. | [sleep_s_to_active_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L461), [sleep_s_to_shutdown](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L819); 8 functions total |
| `18` | W | `ADC_DISABLE` | Write 0 during activation and 1 during sleep. Existing comments number this ADC inconsistently; no ADC number is assigned here. | [sleep_s_to_active_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L523), [active_s_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L709); 10 functions total |
| `FD` | R | `CHIP_ID` | Fallback chip-ID read when selecting SLV-T bank 0 fails. Chip values are defined in cxd2841er_priv.h. | [chip_id](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1708) |

## SLV-T, bank 00

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `2C` | W | `DEMOD_CLOCK_ENABLE` | Write 1 during activation, 0 during sleep. | [sleep_s_to_active_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L493), [active_s_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L745); 10 functions total |
| `2D` | W | `SAT_AUTO_DETECT_00` | S/S2 auto-detection setting, written 0 for a fixed requested system. Companion is AE:30; comments swap their numbering. | [sleep_s_to_active_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L473), [active_s_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L769) |
| `2F` | W | `RF_LEVEL_MONITOR_ENABLE` | Written 0 for DVB-T/T2/C and 1 for ISDB-T activation, then 0 during sleep. | [active_t_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L931), [active_t2_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1066); 8 functions total |
| `30` | W/M | `TC_ADC_CLOCK_CONTROL` | Terrestrial/cable ADC-clock control according to surrounding comments. ISDB-T also sets bit 0 here under a FEC-auto-recovery comment; see bank-context notes. | [active_t_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L925), [active_t2_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1060); 8 functions total |
| `31` | W/M | `SAT_ADC_CLOCK_CONTROL` | Satellite ADC clock: 1 on, 0 off. ISDB-T also clears bit 0 here under a FEC-auto-recovery comment; see bank-context notes. | [sleep_s_to_active_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L499), [active_s_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L721); 3 functions total |
| `32` | M | `TS_INTERFACE_CLOCK_ENABLE` | Bit 0: disable before changing clock selection, then enable. Source field name: OREG_CK_TSIF_EN. | [set_ts_clock_mode](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1635) |
| `33` | M | `TS_INTERFACE_CLOCK_SELECT` | Bits 1:0: 1 for serial TS, 0 for parallel TS. Source field name: OREG_CKSEL_TSIF. | [set_ts_clock_mode](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1645) |
| `41` | W | `TERRESTRIAL_ADC_CONTROL_41` | Activation writes 0x1a; sleep/bias setup writes 0x0a. ADC numbering varies in existing comments. | [active_t_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L919), [active_t2_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1054); 10 functions total |
| `43-44` | W | `TERRESTRIAL_ADC_CONTROL_43` | 0x43-0x44 are written together for crystal-dependent ADC setup; sleep/bias code writes only 0x43=0x0a. Individual bit meanings are not documented. | [active_t_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L913), [active_t2_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1048); 10 functions total |
| `59` | W | `RF_LEVEL_MONITOR_CONTROL_59` | Additional RF-monitor setting: 0 for DVB-T2/C, 1 for ISDB-T. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4724), [sleep_tc_to_active_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5128); 3 functions total |
| `63` | W | `SAT_ADC_CONTROL_63` | Written 0x16 in both satellite activation and sleep/bias setup. Do not interpret this value alone as an on/off switch. | [sleep_s_to_active_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L505), [active_s_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L727); 4 functions total |
| `65` | W | `SAT_ADC_CONTROL_65` | Satellite activation writes 0x3f; sleep/bias setup writes 0x27. | [sleep_s_to_active_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L511), [active_s_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L733); 4 functions total |
| `69` | W | `SAT_ADC_BIAS` | Written 0x06 for SADC bias setup. | [active_s_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L739), [shutdown_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1391); 3 functions total |
| `80` | W | `OUTPUT_HIGH_IMPEDANCE_1` | First Hi-Z control byte; also controls DSQOUT in satellite setup. Values depend on mode (0x10, 0x1f, 0x28, 0x3f); full pin mapping is not documented. | [sleep_s_to_active_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L575), [active_s_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L691); 12 functions total |
| `81` | W | `OUTPUT_HIGH_IMPEDANCE_2` | Second Hi-Z control byte: activation writes 0x00; sleep writes 0xff. | [sleep_s_to_active_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L581), [active_s_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L697); 10 functions total |
| `9C` | W | `DISEQC_INPUT_CONTROL` | DSQIN enable writes 0x40; disable writes 0x00. | [sleep_s_to_shutdown](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L801), [shutdown_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1364) |
| `A5` | M | `ISDB_ASCOT_SETTING_AT_BANK_00` | Bit 0 follows the ASCOT tuner flag in ISDB-T activation. The actual selected bank is 0x00; this is not the same address as 10:A5. Hardware purpose at this bank is unconfirmed. | [sleep_tc_to_active_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5157) |
| `C3` | R/W | `TS_OUTPUT_DISABLE` | Write 1 to stop transport-stream output and 0 to enable it. tune_done reads back bit 0 after enabling. | [retune_active](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L630), [active_s_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L685); 7 functions total |
| `C4` | R/M | `TS_FORMAT_AND_SERIAL_CLOCK` | Bit 7 selects serial (1) versus parallel (0) TS; bits 1:0 are OSERCKMODE (1 serial, 0 parallel here). The TSBITS option clears bits 4:3; their individual meanings are not given. | [set_ts_clock_mode](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1583), [init_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L6446) |
| `CE` | M | `TS_NO_PARITY` | Bit 0 set for DVB-T/T2/C, cleared for ISDB-T. Matching SDK field: ONOPARITY. | [sleep_tc_to_active_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4628), [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4849); 4 functions total |
| `CF` | M | `TS_NO_PARITY_MANUAL_ON` | Bit 0 set for DVB-T/T2/C, cleared for ISDB-T. Matching SDK field: ONOPARITY_MANUAL_ON. | [sleep_tc_to_active_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4634), [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4855); 4 functions total |
| `D1` | M | `TS_SERIAL_CLOCK_DUTY` | Bits 1:0: 1 serial, 0 parallel. Source field name: OSERDUTYMODE. | [set_ts_clock_mode](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1613) |
| `D3` | R | `TS_RATE_CONTROL_OFF` | Read into ts_rate_ctrl_off for debug logging; not decoded or changed here. | [set_ts_clock_mode](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1587) |
| `D9` | W | `TS_CLOCK_PERIOD` | Written 0x08. Source field name: OTSCKPERIOD. | [set_ts_clock_mode](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1625) |
| `DE` | R | `TS_INPUT_OFF` | Read into ts_in_off for debug logging; not decoded or changed here. | [set_ts_clock_mode](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1591) |
| `FD` | R | `CHIP_ID` | Primary chip-ID read. See cxd2841er_priv.h for chip-ID constants. | [chip_id](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1703) |
| `FE` | W | `SOFTWARE_RESET` | Write 0x01 after tuning. Driver waits 15-20 ms before enabling TS output. | [tune_done](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1528) |

## SLV-T, bank 10

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `10` | R | `DVBT_SYNC_STATUS` | Bits 2:0: 6 means demod sync, 7 is rejected as invalid; bit 4=unlock indication; bit 5=TS lock. | [read_status_t_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1780), [read_snr_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2820) |
| `22-23` | R | `DVBT_BIT_ERROR_COUNT` | Two-byte, high-byte-first error count; validity comes from 10:39 and period from 10:6F. | [read_ber_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2580) |
| `26-27` | R | `DVBT_IF_AGC_GAIN` | 12-bit monitor value (first byte bits 3:0 plus second byte), shifted left 4 for relative strength. | [read_agc_gain_t_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2996) |
| `28-29` | R | `DVBT_SNR_MONITOR` | Two-byte, high-byte-first raw SNR value. read_snr_t applies its logarithmic conversion; this is not a dB value itself. | [read_snr_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2827) |
| `39` | R | `DVBT_BER_VALID` | Bit 0 indicates valid BER data. | [read_ber_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2571) |
| `4C-4F` | R | `DVBT_CARRIER_OFFSET` | Signed 29-bit value in four bytes, first byte bits 4:0. The status helper selects bank 0x10 before this read. | [get_carrier_offset_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2079) |
| `66` | M | `DVBT_TS_PARITY_PERIOD` | Bit 0 set to enable the DVB-T parity period. | [set_ts_clock_mode](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1672) |
| `69` | M | `ISDB_ENOD_DETSEL` | ISDB-T initial setting: data 0x04, mask 0x07. Matching SDK field: OREG_ENOD_DETSEL[2:0]. | [sleep_tc_to_active_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5203) |
| `6B` | M | `ISDB_COSNE_CRANGE` | ISDB-T initial setting: data 0x03, mask 0x07. Matching SDK field: OREG_COSNE_CRANGE[2:0]. | [sleep_tc_to_active_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5209) |
| `6F` | R | `DVBT_BER_PERIOD` | Bits 2:0: 0 means 256 measured bits; otherwise the driver uses 4096 shifted left by this field. | [read_ber_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2585) |
| `9D` | M | `ISDB_MER_ASNOS` | ISDB-T initial setting: write 0x50 with mask 0xff. Matching SDK field: OREG_MER_ASNOS[7:0]. | [sleep_tc_to_active_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5215) |
| `9F-A3` | W | `TC_TIMING_RECOVERY_NOMINAL_RATE` | Five-byte nominal timing-recovery rate for DVB-T/ISDB-T; table comments call it TRCG nominal rate. Values depend on bandwidth/crystal. See the 1.712 MHz note for the analogous bank-0x20 block. | [sleep_tc_to_active_t_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3806), [sleep_tc_to_active_i_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4127) |
| `A5` | M | `ASCOT_EQUALIZER_ENABLE` | Bit 0 follows CXD2841ER_ASCOT for DVB-T/T2/C. Nearby coefficient blocks are for ASCOT tuner group-delay equalization. | [sleep_tc_to_active_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4587), [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4797); 3 functions total |
| `A6-B3` | W | `TUNER_GROUP_DELAY_COEFFICIENTS` | Fourteen consecutive coefficient bytes for the ASCOT tuner group-delay equalizer; values depend on bandwidth/crystal. | [sleep_tc_to_active_t2_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3456), [sleep_tc_to_active_t_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3815); 4 functions total |
| `B6-B8` | W | `IF_FREQUENCY` | Three-byte, high-byte-first IF setting, calculated by cxd2841er_calc_iffreq or cxd2841er_calc_iffreq_xtal. | [sleep_tc_to_active_t2_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3470), [sleep_tc_to_active_t_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3829); 4 functions total |
| `BF-C0` | W | `XTAL_SETUP_10_BF_UNKNOWN` | DVB-T 24 MHz setup writes 0xbf=0x60; ISDB-T unconditionally writes 0xbf-0xc0 = 60 00 from data24m. Exact fields are not documented. | [sleep_tc_to_active_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4648), [sleep_tc_to_active_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5295) |
| `CB` | M | `IF_AGC_POLARITY` | Bit 6 set unless CXD2841ER_NO_AGCNEG is requested. Source configuration name: SONY_DEMOD_CONFIG_IFAGCNEG. | [init_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L6426) |
| `CD` | W | `IF_AGC_ADC_FULL_SCALE` | Written 0x50; source labels this SONY_DEMOD_CONFIG_IFAGC_ADC_FS = 0. | [init_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L6435) |
| `D2` | M | `IF_AGC_GAIN_CONTROL` | Bits 4:0: 0x0c for DVB-T/T2, 0x09 for DVB-C. | [sleep_tc_to_active_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4562), [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4772); 3 functions total |
| `D3` | M | `ISDB_FORCE_MODE_GI` | ISDB-T initial setting: data 0x06, mask 0x1f. Matching SDK field: OREG_FORCE_MODEGI,OREG_MODE[1:0],OREG_GI[1:0]. | [sleep_tc_to_active_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5221) |
| `D7` | M | `CHANNEL_BANDWIDTH` | Bits 2:0: 0=8 MHz, 2=7 MHz, 4=6 MHz, 6=5 MHz, 3=1.712 MHz in the applicable tuning paths. | [sleep_tc_to_active_t2_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3474), [sleep_tc_to_active_t_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3833); 3 functions total |
| `D9-DA` | W | `DEMOD_CORE_LATENCY` | Two-byte setting chosen by bandwidth/crystal for DVB-T and ISDB-T. | [sleep_tc_to_active_t_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3848), [sleep_tc_to_active_i_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4164) |
| `DE` | M | `ISDB_FCS_NTHETA` | ISDB-T initial setting: data 0x2e, mask 0x3f. Matching SDK field: OREG_FCS_NTHETA[5:0]. | [sleep_tc_to_active_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5245) |
| `E2` | M | `ISDB_PNC_DISABLE` | ISDB-T initial setting: data 0xce, mask 0x80 (only bit 7 is changed). Matching SDK field: OREG_PNC_DISABLE. | [sleep_tc_to_active_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5233) |
| `EA-EC` | R | `DVBT_PACKET_ERROR_MONITOR` | 0xea-0xeb: 16-bit high-byte-first packet-error count; 0xec bit 0: valid flag. | [read_packet_errors_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2251) |
| `ED` | M | `ISDB_SEQ_SNRSEL` | ISDB-T initial setting: data 0, mask 0x01. Matching SDK field: OREG_SEQ_SNRSEL. | [sleep_tc_to_active_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5227) |
| `F2` | M | `ISDB_TITP_NEF_DISABLE` | ISDB-T initial setting: data 0x13, mask 0x10 (only bit 4 is changed). Matching SDK field: OREG_TITP_NEF_DISABLE. | [sleep_tc_to_active_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5239) |

## SLV-T, bank 11

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `33-35` | W | `DVBT2_24MHZ_SETUP_11_33_UNKNOWN` | Three-byte 24 MHz setup value EB 03 3B. Exact fields are not documented. Later SDK names 33-35 OCTL_IFAGC_INITWAIT/MINWAIT/MAXWAIT, but writes 00 03 3B; retain EB 03 3B. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4924) |
| `6A` | W | `BASEBAND_AGC_TARGET` | Written 0x50 for DVB-T/T2, 0x48 for DVB-C. | [sleep_tc_to_active_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4575), [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4785); 3 functions total |
| `A3` | M | `DVBC_IMR_CHANNEL_WIDTH` | IMR filter width: OREG_IMR_FORCE_CHANNEL_WIDTH and OREG_IMR_CHANNEL_WIDTH[2:0]. Bits 4:0: 0 for 7/8 MHz, 0x14 for 6 MHz; cleared when leaving DVB-C. Names match the later ISDB-C table and DVB-C decompile. | [active_c_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1121), [sleep_tc_to_active_c_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4417) |

## SLV-T, bank 12

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `71` | M | `ISDB_SYR_ACTMODE` | Bits 2:0: 3 for 7/8 MHz, 7 for 6 MHz. Source calls this acquisition optimization. Matching SDK field: OREG_SYR_ACTMODE[2:0]. | [sleep_tc_to_active_i_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4175) |

## SLV-T, bank 13

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `83` | W | `DVBT2_ISIC_POSPROTECT` | DVB-T2 activation writes 0x10; cancellation writes 0x40. Matching SDK field: OREG_ISIC_POSPROTECT[7:0]. | [active_t2_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L986), [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4867) |
| `86` | W | `DVBT2_ISIC_CFNRMOFFSET` | DVB-T2 activation writes 0x34; cancellation writes 0x21. Matching SDK field: OREG_ISIC_CFNRMOFFSET. | [active_t2_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L991), [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4872) |
| `9C-9D` | W | `DVBT_ECHO_OPTIMIZATION` | Two-byte DVB-T echo-performance setting: 01 14. Individual fields are not documented. | [sleep_tc_to_active_t_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3792) |
| `9E` | M | `DVBT2_CFUPONTHRESHOLDMAX_HIGH` | Low nibble set to 0x09 in DVB-T2 activation and cancellation. Matching SDK field: OREG_CFUPONTHRESHOLDMAX[11:8]. | [active_t2_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L996), [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4877) |
| `9F` | W | `DVBT2_CFUPONTHRESHOLDMAX_LOW` | DVB-T2 activation writes 0xd8; cancellation writes 0xfb. Matching SDK field: OREG_CFUPONTHRESHOLDMAX[7:0]. | [active_t2_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1002), [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4883) |

## SLV-T, bank 15

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `BE` | W | `ISDB_FCS_SYMBOL_INTERVAL` | Written 3 for 8 MHz, 2 for 6/7 MHz. Source calls this acquisition optimization. Matching SDK field: OREG_FCS_SYMBOL_INTERVAL_ISDBT[7:0]. | [sleep_tc_to_active_i_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4186) |
| `DE` | M | `ISDB_FCS_F0COEFSEL2` | ISDB-T initial setting: data 2, mask 3. Matching SDK field: OREG_FCS_F0COEFSEL2[1:0]. | [sleep_tc_to_active_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5257) |

## SLV-T, bank 17

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `38-39` | W | `DVBT_NOTCH_FILTER` | Two-byte notch-filter setting selected by bandwidth/crystal. | [sleep_tc_to_active_t_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3861) |

## SLV-T, bank 18

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `24-26` | W | `DVBT_24MHZ_SETUP_18_24_UNKNOWN` | Three bytes DC 6C 00 from data24m in the DVB-T 24 MHz branch. Exact fields are not documented. | [sleep_tc_to_active_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4658) |
| `30` | M | `DVBT_FEC_AUTO_RECOVERY_1` | Bit 0 set to 1; first setting under the FEC-auto-recovery comment. | [sleep_tc_to_active_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4609) |
| `31` | M | `DVBT_FEC_AUTO_RECOVERY_2` | Bit 0 set to 1; second setting under the FEC-auto-recovery comment. | [sleep_tc_to_active_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4615) |
| `36` | M | `DVBT_PRE_RS_BER_SETTING` | Source labels this pre-RS BER monitor setup. Call passes data 0x40, mask 0x07, so the helper actually clears bits 2:0; see notes. | [sleep_tc_to_active_t](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4602) |

## SLV-T, bank 1E

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `73` | M | `ISDB_DAGC_BANDWIDTH_AND_GAIN` | ISDB-T initial setting: write 0x68 with mask 0xff. Matching SDK field: OREG_DAGC_CLIP_BW[2:0],OREG_DAGC_NOSIG_BW[2:0],OREG_DAGC_REDUCE_COARSEGAIN[1:0]. | [sleep_tc_to_active_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5269) |

## SLV-T, bank 20

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `10` | R | `DVBT2_SYNC_STATUS` | Bits 2:0: 6 means demod sync, 7 is rejected as invalid; bit 4=unlock indication; bit 5=TS lock. | [read_status_t_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1780), [read_snr_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2876) |
| `26-27` | R | `DVBT2_IF_AGC_GAIN` | 12-bit monitor value (first byte bits 3:0 plus second byte), shifted left 4 for relative strength. | [read_agc_gain_t_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2996) |
| `28-29` | R | `DVBT2_SNR_MONITOR` | Two-byte, high-byte-first raw SNR value; read_snr_t2 applies the conversion to dB units. | [read_snr_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2883) |
| `39-3C` | R | `DVBT2_BIT_ERROR_MONITOR` | First byte bit 4=valid; low nibble plus next three bytes form a 28-bit error count. | [read_ber_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2506) |
| `4C-4F` | R | `DVBT2_CARRIER_OFFSET` | Signed 28-bit value in four bytes, first byte bits 3:0. The status helper selects bank 0x20 before this read. | [get_carrier_offset_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2124) |
| `6F` | R | `DVBT2_BER_PERIOD` | Bits 3:0 are the period exponent; measured bits = 2^exponent times LDPC block size from 22:5E. | [read_ber_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2520) |
| `8B` | W | `DVBT2_SEQ_SNR_GOODCNT` | Written 0x3c under the acquisition-optimization comment. Matching SDK field: OREG_SEQ_SNR_GOODCNT[7:0]. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4812) |
| `95-97` | W | `DVBT2_24MHZ_SETUP_20_95_UNKNOWN` | Three-byte 24 MHz setup value 5E 5E 47. Exact fields are not documented. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4938) |
| `99` | W | `DVBT2_24MHZ_SETUP_20_99_UNKNOWN` | Written 0x18 in 24 MHz setup. Field purpose is not documented. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4943) |
| `9F-A3` | W | `DVBT2_TIMING_RECOVERY_NOMINAL_RATE` | Five-byte nominal timing-recovery rate selected by bandwidth/crystal. Source table comments say TRCG [37:0], but 1.712 MHz values have higher bits set; preserve all bytes. | [sleep_tc_to_active_t2_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3426) |
| `D9-DA` | W | `DVBT2_24MHZ_SETUP_20_D9_UNKNOWN` | Two-byte 24 MHz setup value 3F FF. Exact fields are not documented. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4951) |

## SLV-T, bank 22

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `5E` | R | `DVBT2_LDPC_BLOCK_SIZE` | Bits 1:0: 0 selects 16200 bits; other values are treated as 64800 bits by this driver. | [read_ber_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2529) |

## SLV-T, bank 23

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `AD` | W | `DVBT2_PLP_SELECTION_MODE` | 0=automatic PLP selection, 1=explicit data PLP selection. | [dvbt2_set_plp_config](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3319) |
| `AF` | W | `DVBT2_DATA_PLP_ID` | Data PLP identifier written for manual selection. | [dvbt2_set_plp_config](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3314) |
| `E6` | M | `DVBT2_L1_CONTROL` | Bits 1:0 cleared during setup. Source calls this L1 control; exact field meaning is not documented. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4836) |

## SLV-T, bank 24

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `34-35` | W | `DVBT2_24MHZ_SETUP_24_34_UNKNOWN` | Two-byte 24 MHz setup value 0B 72. Exact fields are not documented. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4964) |
| `D2-D4` | W | `DVBT2_24MHZ_SETUP_24_D2_UNKNOWN` | Three-byte 24 MHz setup value 93 F3 00. Exact fields are not documented. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4972) |
| `DD-DF` | W | `DVBT2_24MHZ_SETUP_24_DD_UNKNOWN` | Three-byte 24 MHz setup value 05 B8 D8. Exact fields are not documented. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4980) |
| `E0` | W | `DVBT2_24MHZ_SETUP_24_E0_UNKNOWN` | Written 0 in 24 MHz setup. Field purpose is not documented. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4985) |

## SLV-T, bank 25

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `ED` | W | `DVBT2_24MHZ_SETUP_25_ED_UNKNOWN` | Written 0x60 in 24 MHz setup. Field purpose is not documented. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4997) |

## SLV-T, bank 27

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `7A` | M | `DVBT2_TRCG_LMTVAL0` | Bits 3:0: 3 for 1.712 MHz, 0 for the other supported DVB-T2 bandwidths. Matching SDK field: OREG_TRCG_LMTVAL0[3:0]. | [sleep_tc_to_active_t2_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3438) |
| `FA` | W | `DVBT2_24MHZ_SETUP_27_FA_UNKNOWN` | Written 0x34 in 24 MHz setup. Field purpose is not documented. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5009) |

## SLV-T, bank 2A

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `38` | M | `DVBT2_SETUP_2A_38_UNKNOWN` | Low nibble: 4 in activation, 0 in cancellation. Field purpose is not documented. | [active_t2_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1012), [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4894) |

## SLV-T, bank 2B

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `11` | M | `DVBT2_SETUP_2B_11_UNKNOWN` | Bits 5:0: 0x20 in activation, 0 in cancellation. Field purpose is not documented. | [active_t2_to_sleep_tc](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1023), [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4906) |
| `4B` | W | `DVBT2_24MHZ_SETUP_2B_4B_UNKNOWN` | Written 0x2f in 24 MHz setup. Field purpose is not documented. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5021) |
| `76` | M | `DVBT2_NOISE_GAIN_ACQ` | Data 0x20, mask 0x70 in the acquisition-optimization sequence. Matching SDK field: OREG_NOISE_GAIN_ACQ[2:0]. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4823) |
| `9D` | W | `DVBT2_EARLY_UNLOCK_TIME` | BASE profile: 0x0e at 24 MHz, otherwise 0x0c. LITE/ANY: 0x2e at 24 MHz, otherwise 0x28. Time units are not stated. | [dvbt2_set_profile](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3286) |
| `9E` | W | `DVBT2_24MHZ_SETUP_2B_9E_UNKNOWN` | Written 0x0e in 24 MHz setup. Field purpose is not documented. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5026) |

## SLV-T, bank 2D

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `24-25` | W | `DVBT2_24MHZ_SETUP_2D_24_UNKNOWN` | Two-byte 24 MHz setup value 89 89. Exact fields are not documented. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5040) |

## SLV-T, bank 2E

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `10` | M | `DVBT2_PROFILE_TUNE_MODE` | Bits 2:0: 0=ANY, 1=BASE, 5=LITE profile. | [dvbt2_set_profile](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3273) |

## SLV-T, bank 40

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `10` | R | `DVBC_TS_LOCK` | Bit 5 indicates TS lock; driver first checks 40:88 bit 0. | [read_status_c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1817) |
| `15-16` | R | `DVBC_CARRIER_OFFSET` | Signed 14-bit value, first byte bits 5:0 plus second byte; converted with 41000000 / 16384. | [get_carrier_offset_c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2190) |
| `19` | R | `DVBC_DETECTED_QAM` | Bits 2:0: 0=16QAM, 1=32QAM, 2=64QAM, 3=128QAM, 4=256QAM. Used for SNR conversion and modulation reporting. | [read_snr_c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2750), [get_frontend](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5646) |
| `26` | M | `DVBC_TRIAL_SYMBOL_RATE_HIGH` | OREG_TRIAL_SRATE0[11:8], paired with 40:27[7:0]: first trial symbol-rate value. Values by bandwidth: 8 MHz=0x0b3e, 7 MHz=0x09d6, 6 MHz=0x086e. Later-chip names match, but its values differ; retain this recipe. | [sleep_tc_to_active_c_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4441) |
| `27` | W | `DVBC_TRIAL_SYMBOL_RATE_LOW` | OREG_TRIAL_SRATE0[7:0], the low byte of the first trial symbol-rate value described at 40:26. | [sleep_tc_to_active_c_band](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L4447) |
| `49-4A` | R | `DVBC_IF_AGC_GAIN` | 12-bit monitor value (first byte bits 3:0 plus second byte), shifted left 4 for relative strength. | [read_agc_gain_c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2971) |
| `4C-4D` | R | `DVBC_SNR_ESTIMATE` | 13-bit value, first byte bits 4:0 plus second byte. Source name IREG_SNR_ESTIMATE; conversion depends on QAM. | [read_snr_c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2754) |
| `54-55` | W | `DVBC_24MHZ_SETUP_40_54_UNKNOWN` | Two-byte cable_24mhz setup value 29 09. Exact fields are not documented. | [sleep_tc_to_active_c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5490) |
| `60` | R | `DVBC_BER_PERIOD` | Bits 4:0 are the exponent; measured bits = 2^exponent * 204 * 8. | [read_ber_c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2291) |
| `62-64` | R | `DVBC_BIT_ERROR_MONITOR` | First byte bit 7=valid; bits 5:0 plus next two bytes form a 22-bit error count. | [read_ber_c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2279) |
| `66` | M | `DVBC_TS_PARITY_PERIOD` | Bit 0 set to enable the DVB-C parity period. | [set_ts_clock_mode](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1685) |
| `88` | R | `DVBC_ACQUISITION_LOCK` | Bit 0 is called arlock in carrier-offset code; required before TS-lock, offset, SNR and QAM reads. | [read_status_c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1811), [get_carrier_offset_c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2183); 4 functions total |
| `8B-8E` | W | `DVBC_24MHZ_SETUP_40_8B_UNKNOWN` | Four-byte cable_24mhz setup value 08 38 83 0E. Exact fields are not documented. | [sleep_tc_to_active_c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5495) |
| `BF` | W | `DVBC_24MHZ_SETUP_40_BF_UNKNOWN` | Written 0x60 in cable_24mhz setup. Field purpose is not documented. | [sleep_tc_to_active_c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5500) |
| `C3` | M | `DVBC_BNDET_EN_64` | Bit 2 cleared during DVB-C setup. Matching SDK field: OREG_BNDET_EN_64. | [sleep_tc_to_active_c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5453) |
| `EA-EC` | R | `DVBC_PACKET_ERROR_MONITOR` | 0xea-0xeb: 16-bit high-byte-first packet-error count; 0xec bit 0: valid flag. | [read_packet_errors_c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2224) |

## SLV-T, bank 48

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `24-25` | W | `DVBC_24MHZ_SETUP_48_24_UNKNOWN` | Two-byte cable_24mhz setup value DC 6C. Exact fields are not documented. | [sleep_tc_to_active_c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5510) |

## SLV-T, bank 49

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `11-12` | W | `DVBC_24MHZ_SETUP_49_11_UNKNOWN` | Two-byte cable_24mhz setup value 77 00. Exact fields are not documented. | [sleep_tc_to_active_c](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5520) |

## SLV-T, bank 5E

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `8C-8D` | W | `DVBT2_24MHZ_SETUP_5E_8C_UNKNOWN` | Two-byte 24 MHz setup value 24 95. Exact fields are not documented. | [sleep_tc_to_active_t2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5053) |

## SLV-T, bank 60

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `10` | R | `ISDBT_SYNC_STATUS` | Bit 1=demod sync, bit 0=TS lock, bit 4=unlock indication; see read_status_i. This differs from DVB-T/T2 status bit assignments. | [read_status_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1840) |
| `16-18` | R | `ISDBT_BIT_ERROR_COUNT` | 23-bit count, first byte bits 6:0 plus next two bytes. Count is compared with the measured-bit total from 60:5B. | [read_ber_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2341) |
| `26-27` | R | `ISDBT_IF_AGC_GAIN` | 12-bit monitor value (first byte bits 3:0 plus second byte), shifted left 4 for relative strength. | [read_agc_gain_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3019) |
| `28-29` | R | `ISDBT_SNR_MONITOR` | Two-byte, high-byte-first raw value, converted by read_snr_i. | [read_snr_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2933) |
| `4C-4F` | R | `ISDBT_CARRIER_OFFSET` | Signed 29-bit value in four bytes, first byte bits 4:0; conversion depends on channel bandwidth. | [get_carrier_offset_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2020) |
| `5B-5C` | R | `ISDBT_BER_PACKET_COUNT` | Two-byte high-byte-first packet count; measured bits = count * 204 * 8. Zero count is rejected. | [read_ber_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2337) |
| `A8-AA` | W | `ISDB_XTAL_SETUP_60_A8_UNKNOWN` | Three-byte value B7 1B 00 from data24m2. Written unconditionally despite a nearby 24 MHz comment; exact fields are not documented. Later SDK identifies A8/A9 as OPEC_MAXCLKCNT[23:16]/[15:8] and writes B7 1B only; AA remains unconfirmed. | [sleep_tc_to_active_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5305) |

## SLV-T, bank 63

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `81` | M | `ISDB_NPC_FORCE_MOBILE_MODE_ENABLE` | Bit 0 cleared during ISDB-T initial setup. Matching SDK field: OREG_NPC_FORCE_MOBILE_MODE_EN. | [sleep_tc_to_active_i](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L5281) |

## SLV-T, bank A0

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `10` | R | `SAT_TIMING_RECOVERY_LOCK` | Bit 0=ITRL_LOCK, required before reading the sampling-rate mode and carrier offset. | [get_carrier_offset_s_s2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1937) |
| `11` | R | `SAT_TS_LOCK` | Bit 2=ITSLOCK. A set bit produces all FE_HAS_* lock flags in read_status_s. | [read_status_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1742) |
| `1F-20` | R | `SAT_RF_AGC_GAIN` | 13-bit IRFAGC_GAIN in two bytes (first byte bits 4:0); shifted left 3 for relative strength. | [read_agc_gain_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L3048) |
| `35-3F` | R | `DVBS_BIT_ERROR_MONITOR` | 0x35 bit 0=IFVBER_VALID; 0x36-0x38=22-bit IFVBER_BITERR; 0x3d-0x3f=22-bit IFVBER_BITNUM. First count byte uses bits 5:0. The 11-byte read also transfers 0x39-0x3c, which the driver does not interpret. | [mon_read_ber_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2397) |
| `45-47` | R | `SAT_CARRIER_OFFSET` | Signed 21-bit ICFRL_CTRLVAL in three bytes, first byte bits 4:0. Conversion depends on crystal and A0:50 high-sampling mode. | [get_carrier_offset_s_s2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1963) |
| `50` | R | `SAT_HIGH_SAMPLING_MODE` | Bit 4=IHSMODE; selects the carrier-offset conversion scale. | [get_carrier_offset_s_s2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L1945) |
| `7A` | R | `DVBS2_BER_PERIOD` | Bits 3:0 are the exponent; measured bits = 2^exponent * 64800 in this implementation. | [mon_read_ber_s2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2460) |
| `B9` | M | `SAT_IF_AGC_POLARITY` | Bit 0 set to 1; source configuration name SONY_DEMOD_CONFIG_SAT_IFAGCNEG. | [init_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L6387) |

## SLV-T, bank A1

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `10-12` | R | `SAT_CNR_QUICK_MONITOR` | 0x10 bit 0=ICPM_QUICKRDY; 0x11 bits 4:0 plus 0x12 form 13-bit ICPM_QUICKCNDT. Converted with separate DVB-S/S2 lookup tables. | [dvbs_read_snr](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2652) |

## SLV-T, bank A3

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `AC` | W | `SAT_SETUP_A3_AC_UNKNOWN` | Written 0 during satellite activation. Field purpose is not documented. | [sleep_s_to_active_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L534) |

## SLV-T, bank AB

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `98-9B` | W | `SAT_SETUP_AB_98_UNKNOWN` | Four-byte satellite setup value 07 3B 08 C5. Exact fields are not documented. | [sleep_s_to_active_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L549) |
| `A8-AB` | W | `SAT_SETUP_AB_A8_UNKNOWN` | Four-byte satellite setup value 05 80 0A 80. Exact fields are not documented. | [sleep_s_to_active_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L556) |
| `C3-C4` | W | `SAT_SETUP_AB_C3_UNKNOWN` | Two-byte satellite setup value 0C CC. Exact fields are not documented; unrelated to bank-0x00 TS output control. | [sleep_s_to_active_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L561) |

## SLV-T, bank AE

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `20-22` | W | `SAT_SYMBOL_RATE` | Three-byte 20-bit setting, first byte bits 3:0; rounded symbol_rate_in_ksps * 16384 / 1000. Validated as nonzero and at most 0xfffff. | [dvbs2_set_symbol_rate](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L421) |
| `30` | W | `SAT_AUTO_DETECT_AE` | Companion S/S2 auto-detection setting, written 0 for a fixed system. Existing comments swap numbering with 00:2D. | [sleep_s_to_active_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L483), [active_s_to_sleep_s](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L757) |

## SLV-T, bank B2

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `30-34` | R | `DVBS2_BIT_ERROR_MONITOR` | 0x30 bit 0=IFLBER_VALID; 0x31 bits 3:0 plus 0x32-0x34 form 28-bit IFLBER_BITERR. Period comes from A0:7A. | [mon_read_ber_s2](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L2443) |

## SLV-T, bank BB

| Address | Access | Readable name | Meaning in this driver | Source |
| --- | --- | --- | --- | --- |
| `10` | R | `DISEQC_TX_STATUS` | Polled until the entire byte is zero, meaning command transmission finished. | [send_diseqc_msg](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L6264) |
| `32` | W | `DISEQC_TX_START` | Write 1 to start command transmission. | [send_diseqc_msg](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L6257) |
| `33` | W | `DISEQC_ENABLE` | Write 1 before loading the command. | [send_diseqc_msg](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L6227) |
| `34` | W | `DISEQC_MINI_BURST_ENABLE` | Written 1 by send_burst. Sony SetToneBurst decompile confirms BB:34 enables the burst and BB:35 selects A/B; exact vendor register symbol remains unknown. | [send_burst](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L6160) |
| `35` | W | `DISEQC_MINI_BURST_SELECT` | 0=SEC_MINI_A, 1=SEC_MINI_B. | [send_burst](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L6165) |
| `36` | W | `DISEQC_CONTINUOUS_TONE` | 1=SEC_TONE_ON, 0=SEC_TONE_OFF. | [set_tone](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L6196) |
| `37` | W | `DISEQC_COMMAND1_REPEAT_COUNT` | Written 1 for command 1, as described by the source comment. | [send_diseqc_msg](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L6245) |
| `38` | W | `DISEQC_COMMAND2_REPEAT_COUNT` | Written 0; command 2 is not used. | [send_diseqc_msg](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L6251) |
| `3D` | W | `DISEQC_COMMAND1_LENGTH` | Command length in bytes, validated before writing. | [send_diseqc_msg](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L6233) |
| `3E-49` | W | `DISEQC_COMMAND1_DATA` | Twelve-byte block: message bytes followed by zero padding. All twelve registers are written even for a shorter command. | [send_diseqc_msg](upstream/linux/drivers/media/dvb-frontends/cxd2841er.c#L6240) |
