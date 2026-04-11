/**
MIT License

Copyright (c) 2022-2026 Alexandre R. J. Francois

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#include "Phasor.hpp"

#include <cmath>
#include <iostream>

#include <Accelerate/Accelerate.h>

using namespace oscillators_cpp;

Phasor::Phasor(float frequency, float sampleRate, bool angular)
: m_omega(angular ? frequency : -twoPi*frequency/sampleRate), m_sampleRate(sampleRate),
m_Zc(1.0), m_Zs(0.0) {
    updateMultiplier();
}

void Phasor::updateMultiplier() {
    m_Wc = cos(m_omega);
    m_Ws = sin(m_omega);
    m_Wcps = m_Wc + m_Ws;
}

void Phasor::setOmega(float omega) {
    m_omega = omega;
    updateMultiplier();
}

void Phasor::setFrequency(float frequency) {
    m_omega = -twoPi*frequency/m_sampleRate;
    updateMultiplier();
}

void Phasor::setSampleRate(float sampleRate) {
    m_sampleRate = sampleRate;
    updateMultiplier();
}

void Phasor::incrementPhase() {
    // complex multiplication with 3 real multiplications
    const float ac = m_Wc * m_Zc;
    const float bd = m_Ws * m_Zs;
    const float abcd = m_Wcps * (m_Zc + m_Zs);
    m_Zc = ac - bd;
    m_Zs = abcd - ac - bd;
}

void Phasor::stabilize(){
    // approximation for 1 / sqrt(x) around 1 (Taylor expansion)
    // sqrt(m_Zc*m_Zc + m_Zs*m_Zs) should be 1
    const float k = (3.0f - m_Zc*m_Zc - m_Zs*m_Zs) / 2.0f;
    m_Zc *= k;
    m_Zs *= k;
}
