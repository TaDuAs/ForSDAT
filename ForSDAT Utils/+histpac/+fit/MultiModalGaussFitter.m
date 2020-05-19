classdef MultiModalGaussFitter < histpac.fit.IHistogramFitter
    
    properties
        Order (1, 1) uint8 {mustBeFinite(Order), mustBePositive(Order), mustBeLessThan(10), mustBeNonNan(Order), mustBeReal(Order)} = 1;
    end
    
    methods
        function this = MultiModalGaussFitter()
        end
        
        function [mpv, sigma, pdfoo, goodness] = fit(this, y, bins, freq)
            
        end
    end
end

