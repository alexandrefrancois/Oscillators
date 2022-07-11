//
//  Oscillator.hpp
//  
//
//  Created by Alexandre Francois on 11/07/2022.
//

#ifndef OscillatorCpp_hpp
#define OscillatorCpp_hpp

#include <vector>

namespace oscillators_cpp {

class OscillatorCpp {
private:
    float frequency;
    float sampleDuration;
    float amplitude;
    std::vector<float> waveform;
    int phaseIdx;
    
public:
    OscillatorCpp(float targetFrequency, float sampleDuration);
    
    int numSamplesInPeriod();
}

} // oscillators_cpp

#endif /* OscillatorCpp_hpp */

