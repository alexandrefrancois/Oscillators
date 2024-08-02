#include "Oscillator.hpp"
/**
MIT License

Copyright (c) 2022 Alexandre R. J. Francois

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

#include <cmath>
#include <iostream>

#include <Accelerate/Accelerate.h>

using namespace oscillators_cpp;

Oscillator::Oscillator(float frequency, float sampleRate)
: m_frequency(frequency), m_sampleRate(sampleRate), m_amplitude(0.0),
m_Wc(1.0), m_Ws(0.0) {
    const float omega = twoPi * frequency / sampleRate;
    m_Oc = cos(omega);
    m_Os = sin(omega);
    m_Ocs = m_Oc + m_Os;
}

void Oscillator::incrementPhase() {
    // complex multiplication with 3 real multiplications
    const float ac = m_Oc * m_Wc;
    const float bd = m_Os * m_Ws;
    const float abcd = m_Ocs * (m_Wc + m_Ws);
    m_Wc = ac - bd;
    m_Ws = abcd - ac - bd;
}

void Oscillator::stabilize(){
    const float k = (3.0 - m_Wc*m_Wc - m_Ws*m_Ws) / 2.0;
    m_Wc *= k;
    m_Ws *= k;
}
