# dpiny RTK Base Station

A hardware-and-firmware portfolio project for a rugged STM32F407 + UM982 RTK base station with isolated power, dual RS-422 output, USB diagnostics, configuration persistence, and automated bench verification.

dpiny demonstrates the hardware-system side of the portfolio: power architecture, interfaces, embedded firmware, production-oriented diagnostics, and testability are designed as one system rather than separate deliverables.

## System architecture

```text
dual 24 V inputs
      │
protection + isolated power
      │
      ├──> STM32F407 ──> USB CDC / shell / configuration / watchdog
      │        ▲
      │        │ UART + command/state control
      │        ▼
      └────> UM982 GNSS/RTK
               │ RTCM 3.x
               ├──> isolated RS-422 channel 1
               └──> isolated RS-422 channel 2
```

## What it demonstrates

| Area | Engineering work |
| --- | --- |
| Hardware architecture | Dual-input isolated power concept, protected interfaces, STM32 + GNSS integration, USB, and two isolated differential channels |
| Embedded firmware | STM32F407, FreeRTOS, DMA-based UART paths, USB CDC, watchdog aggregation, persistent configuration, and non-blocking device initialization |
| Protocol handling | UM982 command/response control, GNSS status, RTCM 3.x streaming, message configuration, and CRC-aware validation |
| Reliability | Direction-enable timing, ring buffers, dual-output fan-out, task health monitoring, reset recovery, and explicit diagnostics |
| Verification | Command-line build/flash, shell regression, RTCM parsing, SWD register inspection, evidence capture, and repeatable bench checks |

## Engineering proof

- real STM32 target builds and flashes were automated through CMake/Ninja and STM32CubeProgrammer;
- USB CDC and serial shell paths were used for configuration and diagnostics;
- RTCM output was parsed by message type and checked with CRC validation;
- SWD HotPlug register inspection was used to diagnose peripheral-clock, GPIO, USB, and reset problems without relying only on log messages;
- the project serves as the real hardware proof case inside [Liakia](https://github.com/Sailiono/liakia-ai-embedded-workflow), an AI-assisted embedded delivery workflow.

## Repository map

| Path | Purpose |
| --- | --- |
| `Core/` | Application, GNSS, passthrough, shell, configuration, and watchdog code |
| `USB_DEVICE/` | USB CDC integration |
| `Drivers/` | STM32 HAL and CMSIS |
| `Middlewares/` | FreeRTOS and USB middleware |
| `tools/` | Build, bench-test, RTCM, and register-inspection utilities |
| `docs/` | Public project and workflow documentation |
| `dpiny-RTK.ioc` | STM32CubeMX target configuration |

## Build environment

The firmware uses the STM32Cube command-line toolchain with CMake and Ninja. Hardware testing additionally requires the intended target, ST-LINK, UM982 module, serial/USB connections, and the relevant RS-422 capture path.

```bash
cmake --preset Debug
cmake --build --preset Debug
```

The exact programmer, ports, baud rates, and fixtures must be adapted to the local bench. See the tools and [Liakia adoption guide](https://github.com/Sailiono/liakia-ai-embedded-workflow/tree/main/docs/adopt-it) for the evidence-oriented workflow.

## Public release boundary

This is a clean-history public snapshot. It excludes vendor manuals, internal hardware spreadsheets, generated build outputs, local configuration, and test captures. See [`PUBLIC_RELEASE_NOTES.md`](PUBLIC_RELEASE_NOTES.md) and [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

No project-wide reuse license is currently granted for original dpiny files. Bundled third-party components retain their own licenses. Hardware values and interfaces must be verified against the actual editable design source before manufacturing.

## Safety

This repository is an engineering reference and portfolio artifact, not a certified navigation or safety product. Any operational deployment requires independent hardware review, GNSS performance validation, EMC/environmental testing, fault analysis, and application-specific approval.
