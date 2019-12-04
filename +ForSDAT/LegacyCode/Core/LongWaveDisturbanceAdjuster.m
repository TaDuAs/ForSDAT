classdef LongWaveDisturbanceAdjuster < handle
    % Detects a non-linear long wavelength disturbance to the baseline 
    % according to a fourier transform.
    
    properties
        fitToSegmentId = FDCurveTextFileSettings.defaultExtendSegmentName;
        fittingRangeParams;
        fourierSeriesOrder = 2;
    end
    
    methods
        function this = LongWaveDisturbanceAdjuster(fittingRangeParams, fitToSegmentId)
            if exist('fittingRangeParams', 'var') && ~isempty(fittingRangeParams)
                this.fittingRangeParams.a = fittingRangeParams{1};
                if length(fittingRangeParams) > 1
                    this.fittingRangeParams.b = fittingRangeParams{2};
                end
            end
            
            if exist('fitToSegmentId', 'var')
                this.fitToSegmentId = fitToSegmentId;
            end
        end
        
        function fourierFit = adjust(this, segmentIndex, curve)
        % Adjusts long-wavelength disturbances to the baseline
        
            % Fit wave function
            [fFit, zFit, ~] = this.getCurveData(curve);
            fourierFit = fit(zFit(:), fFit(:), ['fourier' num2str(this.fourierSeriesOrder)]);

            segment = curve.getSegment(segmentIndex);
            z = segment.distance;
%             t = segment.time;
            f = segment.force;
            
            % Generate wave vector for the analyzed segment
            waveFVector = this.calcWaveVector(z, fourierFit);
            
            % debug plot
            if Simple.isdebug()
                figure();
                plot(zFit,fFit,z,f,z,waveFVector+fourierFit.a0,z,f-waveFVector);
                legend('Fit To...', 'Retract', 'Fit Wave', 'Retract Signal');
                title('Fourier Fit Baseline');
            end

            segment.force = f - waveFVector;
        end
        
        function waveFVector = calcWaveVector(this, z, fourierFit)
            waveFVector = zeros(1, length(z));
            for i = 1:this.fourierSeriesOrder
                a = fourierFit.(['a' num2str(i)]);
                b = fourierFit.(['b' num2str(i)]);
                waveFVector = waveFVector + a*cos(i*z*fourierFit.w) + b*sin(i*z*fourierFit.w);
            end
        end
        
        function [f, z, t] = getCurveData(this, curve)
            segment = curve.getSegment(this.fitToSegmentId);
            z = croparr(segment.distance, this.fittingRangeParams.a, this.fittingRangeParams.b);
            f = croparr(segment.force, this.fittingRangeParams.a, this.fittingRangeParams.b);
            t = croparr(segment.time, this.fittingRangeParams.a, this.fittingRangeParams.b);
        end
    end 
end