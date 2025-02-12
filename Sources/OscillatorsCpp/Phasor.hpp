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

#ifndef Phasor_hpp
#define Phasor_hpp

#include <vector>

namespace oscillators_cpp {

constexpr float PI = 3.14159274101257324219; // PI
constexpr float twoPi = 2.0 * PI;

// Phasor class: base for individual oscillators
class Phasor {
protected:
    float m_frequency;
    float m_sampleRate;
    
    // Phasor
    float m_Zc;
    float m_Zs;
    float m_Wc;
    float m_Ws;
    float m_Wcps;

    void updateMultiplier();

public:
    Phasor & operator=(const Phasor&) = delete;
    Phasor(const Phasor&) = delete;
    virtual ~Phasor() = default;
    
    Phasor(float frequency, float sampleRate);

    float frequency() const { return m_frequency; }
    void setFrequency(float frequency);
    float sampleRate() const { return m_sampleRate; }

    void incrementPhase();
    void stabilize();
};

} // oscillators_cpp

#endif /* Phasor_hpp */

