# Oscillators

Copyright (c) 2022-2025 Alexandre R. J. François  
Released under MIT License.

This package implements digital sinusoidal oscillator models for signal synthesis and analysis, suitable for real-time audio processing,

The main motivation behind the development of this package is to provide reference Swift and C++ implementations of the _Resonate_ algorithm, a  low latency, low memory footprint, and low computational cost algorithm for evaluating perceptually relevant spectral information from audio signals, at the same time resolution as that of the input signal.

The package offers various implementations of resonator banks independently tuned at arbitrary frequencies. The best candidates on hardware that supports SIMD acceleration are `ResonatorBankVec` (Swift) or its C++ counterpart, which offer a vectorized implementation that uses the Accelerate framework.


## Phasor

### Overview

An oscillator is defined by its frequency and amplitude.
The sinusoidal waveform values are computed recursively using a complex phasor.

A complex phasor _Z = Zc + i Zs_ allows to recursively compute sinusoidals at a specified frequency and sampling rate.
At each step, of duration 1 / sampleRate:

_Z <- Z * W_

where:
  - _W = Wc + i Ws_
  - _w = 2 * PI * frequency / sampleRate_
  - _Wc = cos(w), Ws = sin(w)_
  
_Zc_ and _Zs_ are cosine and sine (resp.) waveforms of same frequency; Z has magnitude 1, which can be used to regularly correct for accumulation of numerical approximations.
  
### Classes

- `Phasor`: the base class for individual oscillators, adopts `PhasorProtocol`

## Oscillator

### Overview

The phasor readily provides a sinusoidal signal to generate a signal at the chosen sampling rate and frequency.

At each tick of the clock (driven by the sampling rate of the output signal),
- iterate the phasor value calculation
- take the current value of either Zc (cosine) or Zs (sine)
- output the value scaled by the amplitude

### Classes

- `Oscillator`: a simple generator class, adopts `OscillatorProtocol`

## Resonators

### Overview

A resonator is an oscillator which, when submitted to an input signal, oscillates with a larger amplitude when its resnonant frequency is present in the input signal. A resonator is characterized by its (resonant) frequency. The sinusoidal waveform is provided by the phasor.

The resonator accumulates the signal's contribution over time using the Exponentially Weighted Moving Average (EWMA), also known as a low-pass filter in signal processing.

The resonator's amplitude is updated at each tick of the clock, i.e. for each input sample, from the resonator's current amplitude value _a_ (in [0,1]), its current waveform value _w_ (in [-1,1]), and the input sample value _s_ (in [-1,1]):  

    _a <- (1-k) * a + k * s * w,  where k in [0,1]_

The pattern _v <- (1-k) * v + k * s_, where k is a constant in [0,1] is the iterative implementation of the EWMA. The single parameter _k_, which can be related to a time constant, controls the dynamics of the system, i.e. how quickly it adapts to variations in the input signal, as well as the frequency resolution.

The instantaneous contribution of each input sample value to the amplitude is proportional to _s * w_, which intuitively will be maximal when peaks in the input signal and peaks in the resonator's waveform are both equally spaced and aligned, i.e. when they have same frequency and are in phase.

In order to account for phase offset, the above calculation is performed at 2 phase values (there are only 2 degrees of freedom). For a sine waveform _sin(x)_, the natural candidates are phases 0 and 𝜋/2, i.e. _sin(x)_ and _sin(x+𝜋/2) = cos(x)_, which are conveniently computed by the oscillator's phasor.

The resonator maintains two values, real and imaginary parts of a complex number _P = Pc + i Ps_, updated at each tick of the clock. For each input sample, from the current value of _P_, the current phasor value _Z_ (of norm 1), and the input sample value _s_:

_P <- (1-k) * P + k * s * Z,  where k in [0,1]_

This is followed by another EWMA to dampen amplitude and phase oscillations.

At any tick, the resonator's amplitude is the norm of P, i.e. _sqrt(pc*pc + ps*ps)_, and the phase offset is _arctan(ps/pc)_.


### Classes

- `Resonator`: computes contributions at 0 and PI/2 (sine and cosine), adopts `ResonatorProtocol`

## Resonator Banks

### Overview

Resonator banks implement independents resonators typically tuned to various frequencies within a range.

### Classes

- `ResonatorBankVec`: a bank of independent resonators implemented as a single array (i.e. vectorized), to allow single calls to Accelerate functions across the resonators. The use of unsafe pointers and of SIMD parallelism makes this implementation extremely efficient on most hardware.
- `ResonatorBankArray`: a bank of independent resonators implemented as instances of the Swift resonator class. The update function for live processing triggers resonator updates in concurrent task groups.

### Concurrency

The Swift `ResonatorBankArray` class implements 2 update functions:
- `update` calls the update function for each resonator sequentially
- `updateConcurrent` calls update for each resonator concurrently, with update calls grouped in a fixed number of concurrent tasks

## C++ Implementation

The package features C++ version of the Oscillator, Resonator and ResonatorBank (as a vector of Resonator instances), in an Objective-C++ wrapper to bridge with Swift. The wrapper provides similar interfaces to the Swift implementations to facilitate comparative performance evaluation.

### C++ classes

- `oscillator_cpp::Phasor`: the base class for independent oscillators
- `oscillator_cpp::Resonator`: resonator (same computations as the Swift `Resonator` implementation)
- `oscillator_cpp::ResonatorBank`: resonator bank as vector of Resonator instances. The update function for live processing triggers resonator updates in sequential or concurrent task groups (using Apple's Grand Central Dispatch).
- `oscillator_cpp::ResonatorBankVec`: a bank of independent resonators implemented as a single vector, to allow single calls to Accelerate functions across the resonators. SIMD parallelism makes this implementation extremely efficient on most hardware.

### Concurrency

The C++ `oscillator_cpp::ResonatorBank` class by defaults utilizes Apple's Grand Central Dispatch to implement the concurrent update function `updateConcurrent`.

The code also provides a sample implementation of the `updateConcurrent` function utilizing `std::async`, which is not used by default.

### Objective-C++ wrappers

These classes provide an Objective-C++ interface for the C++ classes so they can be used in Swift code.

- `PhasorCpp`
- `PhasorCppProtected`
- `ResonatorCpp`
- `ResonatorBankCpp`
- `ResonatorBankVecCpp`
