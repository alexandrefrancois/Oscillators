# Oscillators

Copyright (c) 2022-2024 Alexandre R. J. François  
Released under MIT License.

This package implements digital oscillator models for signal synthesis and analysis, suitable for real-time audio processing.

## Oscillator

### Overview

An oscillator is defined by its frequency and amplitude.
The waveform values are computed recursively using a complex phasor.

### Classes

- `Oscillator`: the base oscillator class, adopts `OscillatorProtocol`

## Generator

### Overview

A complex phasor Z = Zc + i Zs allows to compute a sinusoidal at a specified frequency and sampling rate:

Z <- Z * W

where:
  W = Wc + i Ws
  omega = 2 * PI * frequency / sampleRate
  Wc = cos(omega)
  Ws = sin(omega)

### Classes

- `Generator`: a simple generator class, adopts `GeneratorProtocol`

## Resonators

### Overview

A resonator is an oscillator which, when submitted to an input signal, oscillates with a larger amplitude when its resnonant frequency is present in the input signal. A resonator is characterized by its (resonant) frequency and the shape of its periodic signal, captured in the oscillator model as the waveform array.

The resonator's amplitude is updated at each tick of the clock, i.e. for each input sample, from the resonator's current amplitude value _a_ (in [0,1]), its current waveform value _w_ (in [-1,1]), and the input sample value _s_ (in [-1,1]):  
    _a <- (1-k) * a + k * s * w,  where k in [0,1]_

The pattern _v <- (1-k) * v + k * s_, where k is a constant in [0,1], is known as a low-pass filter, as it smooths out high frequency variations in the input signal. The constant _k_ dictates the "smoothing", in this case the dynamic behavior of the system, i.e. how quickly it adapts to variations in the input signal. This is also known as an exponentially weighted moving average.

The instantaneous contribution of each input sample value to the amplitude is proportional to _s * w_, which intuitively will be maximal when peaks in the input signal and peaks in the resonator's waveform are both equally spaced and aligned, i.e. when they have same frequency and are in phase.

In order to account for phase offset, the above calculation is performed at 2 phase values (there are only 2 degrees of freedom). For a sine waveform _sin(x)_, the natural candidates are phases 0 and 𝜋/2, i.e. _sin(x)_ and _sin(x+𝜋/2) = cos(x)_, which are conveniently the oscillator's phasor values.

The resonator maintains two values, _ps_ and _pc_ (both in [0,1]), updated at each tick of the clock, i.e. for each input sample, from their current values, the current phasor values values _Zs_ and _Zc_ (both in [-1,1]), and the input sample value _s_ (in [-1,1]):  
_ps <- (1-k) * ps + k * s * Zs_  
_pc <- (1-k) * pc + k * s * Zc_

At any tick, the resonator's amplitude is _sqrt(ps*ps + pc*pc)_ and the phase offset _arctan(ps/pc)_.

All implementations use the Accelerate framework where relevant.

### Classes

- `Resonator`: computes contributions at 0 and PI/2 (sine and cosine), adopts `ResonatorProtocol`

## Resonator Banks

### Overview

Resonator banks implement independents resonators typically tuned to various frequencies within a range.

All implementations use the Accelerate framework with unsafe pointers.

### Classes

- `ResonatorBankArray`: a bank of independent resonators implemented as instances of the Swift resonator class. The update function for live processing triggers resonator updates in concurrent task groups.
- `ResonatorBankSingle`: a bank of independent resonators implemented as a single array, resulting in single calls to Accelerate functions across the resonators.

### Concurrency and Update Heuristics

The Swift `ResonatorBankArray` class implementes 2 update functions:
- `update` calls the update function for each resonator sequentially
- `updateConcurrent` calls update for each resonator concurrently, with update calls grouped in a fixed number of concurrent tasks

## C++ Implementation

The package features C++ version of the Oscillator, Resonator and ResonatorBank (as a vector of Resonator instances), in an Objective-C++ wrapper to bridge with Swift. The wrapper provides similar interfaces to the Swift implementations to facilitate comparative performance evaluation.

### C++ classes

- `oscillator_cpp::Oscillator`: the base oscillator class
- `oscillator_cpp::Resonator`: resonator (same computations as the Swift `Resonator` implementation)
- `oscillator_cpp::ResonatorBank`: resonator bank as vector of Resonator instances. The update function for live processing triggers resonator updates in sequential or concurrent task groups (using Apple's Grand Central Dispatch).

### Concurrency and Update Heuristics

The C++ `oscillator_cpp::ResonatorBank` class by defaults utilizes Apple's Grand Central Dispatch to implement the concurrent update functions `updateConcurrent`.

The code also provides a sample implementation of the `updateConcurrent` function utilizing `std::async`, which is not used by default.

### Objective-C++ wrappers

These classes provide an Objective-C++ interface for the C++ classes so they can be used in Swift code.

- `OscillatorCpp`
- `OscillatorCppProtected`
- `ResonatorCpp`
- `ResonatorBankCpp`
