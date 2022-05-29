# Oscillators

Copyright (c) 2022 Alexandre R. J. François  
Released under MIT License.

This package implements simple oscillator models for signal generation and analysis.

## Oscillator

An oscillator is defined by its amplitude (a scaling factor) and an array, whose length is the number of samples in the period, and which contains the waveform value at each sample time.

**By design, the oscillators modeled in this package cannot be tuned to any arbitrary frequency, but only to frequencies that correspond to a period duration that is a multiple of the sample duration.**

## Generator

To generate a signal at the chosen sampling rate, all that is needed is a pointer that keeps track of the oscillator's position in the period, in this case an index into the waveform.

At each tick of the clock (driven by the sampling rate of the output signal),
- advance the pointer to the next position
  - if past the end of the waveform, go back to first position (= repeat the period)
- take the waveform value at the current position,
- output the value scaled by the amplitude

## Resonators

A resonator is an oscillator which, when submitted to an input signal, oscillates with a larger amplitude when its resnonant frequency is present in the input signal. A resonator is characterized by its (resonant) frequency and the shape of its periodic signal, captured in the oscillator model as the waveform array.

The resonator's amplitude is updated at each tick of the clock, i.e. for each input sample, from the resonator's current amplitude value _a_ (in [0,1]), its current position in the oscillation period (waveform value _w_), and the input sample value _s_ (in [0,1]):  
    _a <- (1-k) * a + k * s * w_  

All implementations use the Accelerate framework.

- `ResonatorSafe`: uses Swift Arrays
- `Resonator`: uses Swift unsafe pointers (manual memory management)

## Resonator Banks

Resonator banks implement independents resonators typically tuned to various frequencies within a range.
All implementations use the Accelerate framework with unsafe pointers.

- `ResonatorBankSingle`: a bank of independent resonators implemented as a single array, resulting in single calls to Accelerate functions across the resonators.
- `ResonatorBankArray`: a bank of independent resonators implemented as instances of the Swift resonator class

## C++ Implementation

The package features C++ version of the Oscillator, Resonator and ResonatorBank (as a vector of Resonator instances), wrapped in an Objective-C++ wrapper to bridge with Swift. The wrapper provides similar interfaces to the Swift implementations to facilitate comparative performance evaluation.
