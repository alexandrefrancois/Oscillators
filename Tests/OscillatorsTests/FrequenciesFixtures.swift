/**
MIT License

Copyright (c) 2022-2024 Alexandre R. J. Francois

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

class FrequenciesFixtures {
    static var frequencies: [Float] = [
        220, 233.081863, 246.94165, 261.625549, 277.182648, 293.664764, 311.126984, 329.627563, 349.228241, 369.994415, 391.995422, 415.304688,
        440, 466.163788, 493.883301, 523.251099, 554.365295, 587.329529, 622.253967, 659.255126, 698.456482, 739.98883, 783.990845, 830.609375]
    
    
    static var melFrequencies: [Float] = [
        0.0,            26.19978713,    52.39957426,    78.59936139,
        104.79914851,   130.99893564,   157.19872277,   183.3985099,
        209.59829703,   235.79808416,   261.99787129,   288.19765842,
        314.39744554,   340.59723267,   366.7970198,    392.99680693,
        419.19659406,   445.39638119,   471.59616832,   497.79595545,
        523.99574257,   550.1955297,    576.39531683,   602.59510396,
        628.79489109,   654.99467822,   681.19446535,   707.39425247,
        733.5940396,    759.79382673,   785.99361386,   812.19340099,
        838.39318812,   864.59297525,   890.79276238,   916.9925495,
        943.19233663,   969.39212376,   995.59191089,  1022.72769586,
        1050.73771015,  1079.51485035,  1109.08012615,  1139.45512266,
        1170.66201615,  1202.72359026,  1235.6632526,   1269.50505185,
        1304.27369535,  1339.9945671,   1376.6937463,   1414.39802641,
        1453.13493468,  1492.93275229,  1533.82053494,  1575.82813412,
        1618.98621886,  1663.32629817,  1708.88074397,  1755.68281482,
        1803.7666801,   1853.16744504,  1903.92117631,  1956.06492834,
        2009.63677042,  2064.67581445,  2121.22224349,  2179.31734115,
        2239.00352168,  2300.32436096,  2363.32462828,  2428.0503191,
        2494.54868854,  2562.86828595,  2633.0589903,   2705.17204666,
        2779.26010355,  2855.3772514,   2933.57906207,  3013.92262939,
        3096.46661083,  3181.27127037,  3268.39852245,  3357.91197723,
        3449.87698695,  3544.36069374,  3641.43207854,  3741.16201155,
        3843.6233039,   3948.89076085,  4057.04123642,  4168.15368942,
        4282.3092412,   4399.5912348,   4520.08529583,  4643.87939496,
        4771.0639122,   4901.7317028,   5035.97816512,  5173.90131024,
        5315.60183352,  5461.18318814,  5610.75166058,  5764.41644826,
        5922.28973926,  6084.48679421,  6251.12603044,  6422.32910845,
        6598.22102073,  6778.93018299,  6964.58852795,  7155.33160164,
        7351.29866237,  7552.63278237,  7759.48095231,  7971.99418854,
        8190.3276434,   8414.64071846,  8645.09718092,  8881.86528316,
        9125.11788558,  9375.0325828,   9631.79183335,  9895.58309281,
        10166.59895075, 10445.03727127, 10731.1013375,  11025.0
    ]
    
    static var melFrequenciesHTK: [Float] = [
        0.0,            15.70813224,   31.76875793,    48.18978709,
        64.97930726,    82.14558742,    99.69708216,   117.64243575,
        135.99048647,   154.75027092,   173.93102847,   193.54220584,
        213.59346174,   234.0946716,    255.05593249,   276.48756804,
        298.40013353,   320.80442114,   343.71146519,   367.13254763,
        391.07920359,   415.56322704,   440.59667659,   466.19188148,
        492.36144761,   519.11826374,   546.47550788,   574.44665375,
        603.04547741,   632.28606409,   662.18281505,   692.75045474,
        724.00403805,   755.95895767,   788.63095173,   822.0361115,
        856.19088937,   891.11210691,   926.81696316,   963.32304314,
        1000.64832644,  1038.81119616,  1077.83044788,  1117.72529898,
        1158.51539807,  1200.22083469,  1242.86214919,  1286.46034285,
        1331.0368882,   1376.61373965,  1423.21334426,  1470.85865281,
        1519.57313107,  1569.38077143,  1620.30610465,  1672.37421196,
        1725.61073744,  1780.04190061,  1835.69450937,  1892.59597317,
        1950.77431658,  2010.258193,    2071.07689884,  2133.26038793,
        2196.83928627,  2261.84490709,  2328.30926633,  2396.26509834,
        2465.74587206,  2536.78580747,  2609.41989245,  2683.68390002,
        2759.61440594,  2837.24880677,  2916.62533821,  2997.78309401,
        3080.76204519,  3165.60305971,  3252.34792262,  3341.03935663,
        3431.72104319,  3524.43764392,  3619.23482268,  3716.15926805,
        3815.25871628,  3916.58197485,  4020.17894648,  4126.10065372,
        4234.39926409,  4345.12811573,  4458.34174372,  4574.09590691,
        4692.44761539,  4813.45515856,  4937.17813386,  5063.6774761,
        5193.01548748,  5325.25586826,  5460.46374818,  5598.70571846,
        5740.04986466,  5884.56580021,  6032.32470066,  6183.39933874,
        6337.86412024,  6495.79512062,  6657.27012248,  6822.36865388,
        6991.17202752,  7163.76338076,  7340.22771656,  7520.65194539,
        7705.12492801,  7893.7375192,   8086.58261257,  8283.75518626,
        8485.35234976,  8691.47339169,  8902.21982874,  9117.69545564,
        9338.00639632,  9563.26115613,  9793.5706753,  10029.04838359,
        10269.81025614, 10515.97487058, 10767.66346548, 11025.0
    ]
}

