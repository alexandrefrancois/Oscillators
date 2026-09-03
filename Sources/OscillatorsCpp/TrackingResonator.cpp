/**
MIT License

Copyright (c) 2025-2026 Alexandre R. J. Francois

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

#include "TrackingResonator.hpp"
#include "FrameStride.hpp"

#include <Accelerate/Accelerate.h>

using namespace oscillators_cpp;

constexpr float minPowerThreshold = 1e-12;

TrackingResonator::TrackingResonator(float naturalFrequency, float sampleRate, float alpha, float beta, float gamma, TrackingRule trackingRule, float thresholdDB)
    : ResonatorBase(naturalFrequency, sampleRate, alpha, beta, gamma),
    m_trackingRule(trackingRule),
    m_trackingPowerThreshold(0.001) {
        // natural frequency is not angular
        const float omega = -twoPi*naturalFrequency/sampleRate;
        setNaturalW(cos(omega), sin(omega));
        setPowerThresholdDB(thresholdDB);
}

void TrackingResonator::setNaturalFrequency(float frequency, float alpha, float beta, float gamma) {
    const float omega = -twoPi*frequency/m_sampleRate;
    setNaturalW(cos(omega), sin(omega));
    setAlpha(alpha);
    setBeta(beta);
    setGamma(gamma);
}

void TrackingResonator::setNaturalW(float c, float s) {
    m_naturalWc = c;
    m_naturalWs = s;
}

void TrackingResonator::restoreNaturalW() {
    setW(m_naturalWc, m_naturalWs);
}

void TrackingResonator::setPowerThresholdDB(float thresholdDB) {
    m_trackingPowerThresholdRatio = pow(10.0, thresholdDB / 10.0);
}

void TrackingResonator::updateTracking() {
    if (power() > m_trackingPowerThreshold) {
        switch (m_trackingRule) {
        case TrackingRule::ewma:
            applyEWMATracking();
            break;
        case TrackingRule::normalizedChord:
            applyChordCorrectionTracking();
            break;
        case TrackingRule::tangent:
            applyTangentCorrectionTracking();
            break;
        }

        // is this really necessary?
//        normalizeW();
    } else {
        restoreNaturalW();
    }
}

void TrackingResonator::applyEWMATracking() {
    setOmega(omega() - m_gamma * atan2(m_dps, m_dpc));
}

void TrackingResonator::applyChordCorrectionTracking() {
    const float residualMagnitudeSquared = m_dpc * m_dpc + m_dps * m_dps;

    if (residualMagnitudeSquared <= minimumResidualMagnitudeSquared ||
        !std::isfinite(residualMagnitudeSquared)) {
        return;
    }

    const float inverseResidualMagnitude = 1.0f / sqrt(residualMagnitudeSquared);

    rotateW(
        m_omGamma + m_gamma * m_dpc * inverseResidualMagnitude,
        -m_gamma * m_dps * inverseResidualMagnitude
    );
}

void TrackingResonator::applyTangentCorrectionTracking() {
    const float residualMagnitudeSquared = m_dpc * m_dpc + m_dps * m_dps;

    if (residualMagnitudeSquared <= minimumResidualMagnitudeSquared ||
        !std::isfinite(residualMagnitudeSquared)) {
        return;
    }

    const float inverseResidualMagnitude = 1.0f / sqrt(residualMagnitudeSquared);

    rotateW(
        1.0f,
        -m_gamma * m_dps * inverseResidualMagnitude
    );
}

void TrackingResonator::updateWithSample(float sample) {
    const float lcc = m_cc;
    const float lss = m_ss;
    updateResonatorWithSample(sample);
    updateDeltaPhase(lcc, lss);
    updateTracking();
    incrementPhase();
}

void TrackingResonator::update(float sample, float maxPower) {
    m_trackingPowerThreshold = maxPower * m_trackingPowerThresholdRatio;
//    m_trackingPowerThreshold = fmax(minPowerThreshold, m_trackingPowerThreshold);
    updateWithSample(sample);
    stabilize();
}

void TrackingResonator::update(const std::vector<float> &samples, float maxPower) {
    m_trackingPowerThreshold = maxPower * m_trackingPowerThresholdRatio;
//    m_trackingPowerThreshold = fmax(minPowerThreshold, m_trackingPowerThreshold);
    for (float sample : samples) {
        updateWithSample(sample);
    }
    stabilize();
}

void TrackingResonator::update(const float *frameData, size_t frameLength, size_t sampleStride, float maxPower) {
    m_trackingPowerThreshold = maxPower * m_trackingPowerThresholdRatio;
//    m_trackingPowerThreshold = fmax(minPowerThreshold, m_trackingPowerThreshold);
    const size_t sampleSpan = frameSampleSpan(frameLength, sampleStride);
    for (size_t sampleIndex = 0; sampleIndex < sampleSpan; sampleIndex += sampleStride) {
        updateWithSample(frameData[sampleIndex]);
    }
    stabilize();
}
