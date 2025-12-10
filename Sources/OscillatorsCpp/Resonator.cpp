/**
MIT License

Copyright (c) 2022-2025 Alexandre R. J. Francois

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

#include "Resonator.hpp"

#include <Accelerate/Accelerate.h>

using namespace oscillators_cpp;

Resonator::Resonator(float frequency, float alpha, float beta, float gamma, float sampleRate) : Phasor(frequency, sampleRate),
m_alpha(alpha), m_omAlpha(1.0 - alpha), m_beta(beta), m_omBeta(1.0 - beta), m_gamma(gamma), m_omGamma(1.0 - gamma),
m_dpc(1.0), m_dps(0.0) {
}

void Resonator::setAlpha(float alpha) {
    if (alpha < 0.0 || alpha >1.0) {
        throw std::out_of_range("Bad alpha passed to setAlpha()");
    }
    m_alpha = alpha;
    m_omAlpha = 1.0 - m_alpha;
}

void Resonator::setBeta(float beta) {
    if (beta < 0.0 || beta >1.0) {
        throw std::out_of_range("Bad beta passed to setBeta()");
    }
    m_beta = beta;
    m_omBeta = 1.0 - m_beta;
}

void Resonator::setGamma(float gamma) {
    if (gamma < 0.0 || gamma >1.0) {
        throw std::out_of_range("Bad gamma passed to setGamma()");
    }
    m_gamma = gamma;
    m_omGamma = 1.0 - m_gamma;
}

float Resonator::phase() const {
    return atan2(m_ss, m_cc); // returns value in [-pi,pi]
}

float Resonator::deltaPhase() const {
    return atan2(m_dps, m_dpc); // returns value in [-pi,pi]
}

void Resonator::updateWithSample(float sample) {
    const float alphaSample = m_alpha * sample;
    m_cos = m_omAlpha * m_cos + alphaSample * m_Zc;
    m_sin = m_omAlpha * m_sin + alphaSample * m_Zs;
    const float lcc = m_cc;
    const float lss = m_ss;
    m_cc = m_omBeta * m_cc + m_beta * m_cos;
    m_ss = m_omBeta * m_ss + m_beta * m_sin;
    // compute current * conjugate(previous)
    // the phase time derivative estimate is the arg of this complex number
    // Smoothing (EWMA) with gamma = alpha
    m_dpc = m_omAlpha * m_dpc + m_alpha * (m_cc * lcc + m_ss * lss);
    m_dps = m_omAlpha * m_dps + m_alpha * (m_ss * lcc - m_cc * lss);
    incrementPhase();
}

void Resonator::update(const float sample) {
    updateWithSample(sample);
    stabilize(); // this is overkill but necessary
}

void Resonator::update(const std::vector<float> &samples) {
    for (float sample : samples) {
        updateWithSample(sample);
    }
    stabilize(); // this is overkill but necessary
}

void Resonator::update(const float *frameData, size_t frameLength, size_t sampleStride) {
    for (int i=0; i<frameLength; i += sampleStride) {
        updateWithSample(frameData[i]);
    }
    stabilize(); // this is overkill but necessary
}
