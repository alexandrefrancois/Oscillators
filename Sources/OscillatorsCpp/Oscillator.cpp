//
//  OscillatorCpp.cpp
//  
//
//  Created by Alexandre Francois on 11/07/2022.
//

#include "OscillatorCpp.hpp"

#include <cmath>
#include <iostream>

using namespace oscillators_cpp;

OscillatorCpp::OscillatorCpp(float targetFrequency, float sampleDuration) {
    this.sampleDuration = sampleDuration;
    
    int numSamplesInPeriod = static_cast<int>(std::round((1.0 / (sampleDuration * targetFrequency))))
    this.frequency = 1.0 / (maxNumSamplesInPeriod * sampleDuration)
    
    this.waveform = std::vector<float>(numSamplesInPeriod, 0);
    this.phaseIdx = 0;
    
    std::cout << "New OscillatorCpp: target frequency: " << targetFrequency
    << ", num samples in period: " << numSamplesInPeriod
    << " -> " << this.frequency << std::endl;
}

int OscillatorCpp::numSamplesInPeriod() {
    return this.waveform.size();
}
