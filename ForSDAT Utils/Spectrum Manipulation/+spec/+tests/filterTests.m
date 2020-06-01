classdef filterTests < matlab.unittest.TestCase
    methods
        function [t, x, Fs, freqs, amps] = prepSignal(testCase)
            % prep time sample
            sampleSize = 10000;
            
            Fs = 100000;
            T = 1/Fs;
            t = ((0:sampleSize-1)*T)';
            freqs = [150 250 750 1000 1500 25000]; % Hz
            amps  = [5   2.5 10  6    3    1];
            
            x = sum(sin(2*pi*t*freqs).*amps, 2);
        end
    end
    
    methods (Test) % band pass filter
        function bandPassFilter(testCase)
            [~, x, Fs, freqs, amps] = testCase.prepSignal();
            filter = tada.filters.bandPassFilter([145 155]);
            
            [~, ampSpec, fh] = tada.filterSpectrum(x, Fs, filter);
            
            f150 = fh == 150;
            testCase.verifyEqual(ampSpec(f150), amps(freqs == 150), 'AbsTol', 1e-10);
            testCase.verifyEqual(ampSpec(~f150), zeros(size(ampSpec(~f150))), 'AbsTol', 1e-10);
        end
        
        function bandPassFilter_2Bands(testCase)
            [~, x, Fs, freqs, amps] = testCase.prepSignal();
            filter = tada.filters.bandPassFilter([145 155; 1499.9 1500.1]);
            
            [~, ampSpec, fh] = tada.filterSpectrum(x, Fs, filter);
            
            f150 = fh == 150;
            testCase.verifyEqual(ampSpec(f150), amps(freqs == 150), 'AbsTol', 1e-10);
            
            f1500 = fh == 1500;
            testCase.verifyEqual(ampSpec(f1500), amps(freqs == 1500), 'AbsTol', 1e-10);
            
            testCase.verifyEqual(ampSpec(~f1500 & ~f150), zeros(size(ampSpec(~f1500 & ~f150))), 'AbsTol', 1e-10);
        end
        
        function bandPassFilter_MissingBand(testCase)
            [~, x, Fs] = testCase.prepSignal();
            filter = tada.filters.bandPassFilter([50, 120]);
            
            [~, ampSpec] = tada.filterSpectrum(x, Fs, filter);
            
            testCase.verifyEqual(ampSpec, zeros(size(ampSpec)), 'AbsTol', 1e-10);
        end
        
        function bandPassFilter_LargeBand(testCase)
            [~, x, Fs, freqs, amps] = testCase.prepSignal();
            filter = tada.filters.bandPassFilter([0, 800]);
            
            [~, ampSpec, fh] = tada.filterSpectrum(x, Fs, filter);
            
            fIn = ismember(fh, freqs(freqs < 800));
            testCase.verifyEqual(ampSpec(fIn), amps(freqs < 800)', 'AbsTol', 1e-10);
        end
    end
    
    methods (Test) % band reject filter
        function bandRejectFilter(testCase)
            [~, x, Fs, freqs, amps] = testCase.prepSignal();
            filter = tada.filters.bandRejectFilter([145 155]);
            
            ampSpec0 = tada.spectrum(x, Fs);
            [~, ampSpec, fh] = tada.filterSpectrum(x, Fs, filter);
            
            f150 = fh == 150;
            testCase.verifyEqual(ampSpec(~f150), ampSpec0(~f150), 'AbsTol', 1e-10);
            testCase.verifyEqual(ampSpec(f150), 0, 'AbsTol', 1e-10);
        end
        
        function bandRejectFilter_2Bands(testCase)
            [~, x, Fs, freqs, amps] = testCase.prepSignal();
            filter = tada.filters.bandRejectFilter([145 155; 1499.9 1500.1]);
            
            ampSpec0 = tada.spectrum(x, Fs);
            [~, ampSpec, fh] = tada.filterSpectrum(x, Fs, filter);
            
            f150 = fh == 150;
            testCase.verifyEqual(ampSpec(f150), 0, 'AbsTol', 1e-10);
            
            f1500 = fh == 1500;
            testCase.verifyEqual(ampSpec(f1500), 0, 'AbsTol', 1e-10);
            
            testCase.verifyEqual(ampSpec(~f1500 & ~f150), ampSpec0(~f1500 & ~f150), 'AbsTol', 1e-10);
        end
        
        function bandRejectFilter_MissingBand(testCase)
            [~, x, Fs] = testCase.prepSignal();
            filter = tada.filters.bandRejectFilter([50, 120]);
            
            ampSpec0 = tada.spectrum(x, Fs);
            [~, ampSpec] = tada.filterSpectrum(x, Fs, filter);
            
            testCase.verifyEqual(ampSpec, ampSpec0(:), 'AbsTol', 1e-10);
        end
        
        function bandRejectFilter_LargeBand(testCase)
            [~, x, Fs, freqs, amps] = testCase.prepSignal();
            filter = tada.filters.bandRejectFilter([0, 800]);
            
            [~, ampSpec, fh] = tada.filterSpectrum(x, Fs, filter);
            
            fIn = ismember(fh, freqs(freqs > 800));
            testCase.verifyEqual(ampSpec(fIn), amps(freqs > 800)', 'AbsTol', 1e-10);
        end
    end
    
    methods (Test) % band intensity filter
        function bandIntensityFilter(testCase)
            [~, x, Fs, freqs, amps] = testCase.prepSignal();
            filter = tada.filters.bandIntensityFilter([145 155 0.5]);
            
            ampSpec0 = tada.spectrum(x, Fs);
            [~, ampSpec, fh] = tada.filterSpectrum(x, Fs, filter);
            
            f150 = fh == 150;
            testCase.verifyEqual(ampSpec(f150), amps(freqs == 150) / 2, 'AbsTol', 1e-10);
            testCase.verifyEqual(ampSpec(~f150), ampSpec0(~f150), 'AbsTol', 1e-10);
        end
        
        function bandIntensityFilter_2Bands(testCase)
            [~, x, Fs, freqs, amps] = testCase.prepSignal();
            filter = tada.filters.bandIntensityFilter([145 155 0.5; 1499.9 1500.1 0.1]);
            
            ampSpec0 = tada.spectrum(x, Fs);
            [~, ampSpec, fh] = tada.filterSpectrum(x, Fs, filter);
            
            f150 = fh == 150;
            testCase.verifyEqual(ampSpec(f150), amps(freqs == 150)*0.5, 'AbsTol', 1e-10);
            
            f1500 = fh == 1500;
            testCase.verifyEqual(ampSpec(f1500), amps(freqs == 1500)*0.1, 'AbsTol', 1e-10);
            
            testCase.verifyEqual(ampSpec(~f1500 & ~f150), ampSpec0(~f1500 & ~f150), 'AbsTol', 1e-10);
        end
        
        function bandIntensityFilter_MissingBand(testCase)
            [~, x, Fs] = testCase.prepSignal();
            filter = tada.filters.bandIntensityFilter([50, 120, 0.5]);
            
            ampSpec0 = tada.spectrum(x, Fs);
            [~, ampSpec] = tada.filterSpectrum(x, Fs, filter);
            
            testCase.verifyEqual(ampSpec, ampSpec0, 'AbsTol', 1e-10);
        end
        
        function bandIntensityFilter_LargeBand(testCase)
            [~, x, Fs, freqs, amps] = testCase.prepSignal();
            filter = tada.filters.bandIntensityFilter([0, 800, 2]);
            
            ampSpec0 = tada.spectrum(x, Fs);
            [~, ampSpec, fh] = tada.filterSpectrum(x, Fs, filter);
            
            fIn = ismember(fh, freqs(freqs < 800));
            testCase.verifyEqual(ampSpec(fIn), 2*amps(freqs < 800)', 'AbsTol', 1e-10);
            testCase.verifyEqual(ampSpec(~fIn), ampSpec0(~fIn), 'AbsTol', 1e-10);
        end
    end
end

