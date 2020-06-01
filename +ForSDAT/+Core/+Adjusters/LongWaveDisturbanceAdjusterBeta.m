classdef LongWaveDisturbanceAdjusterBeta < handle
    % Detects a non-linear long wavelength disturbance to the baseline 
    % according to a fourier transform.
    
    properties
        fitToSegmentId = ForSDAT.Application.IO.FDCurveTextFileSettings.defaultExtendSegmentName;
        fixSegmentId = ForSDAT.Application.IO.FDCurveTextFileSettings.defaultRetractSegmentName;
        fittingRangeParams;
        fourierSeriesOrder = 2;
    end
    
    methods
        function this = LongWaveDisturbanceAdjusterBeta(...
                fittingRangeParams,...
                fourierSeriesOrder,...
                fitToSegmentId,...
                fixSegmentId)
            if exist('fittingRangeParams', 'var') && ~isempty(fittingRangeParams)
                this.fittingRangeParams.a = fittingRangeParams{1};
                if length(fittingRangeParams) > 1
                    this.fittingRangeParams.b = fittingRangeParams{2};
                end
            end
            
            if exist('fourierSeriesOrder', 'var') && ~isempty(fourierSeriesOrder)
                this.fourierSeriesOrder = fourierSeriesOrder;
            end
            
            if exist('fitToSegmentId', 'var') && ~isempty(fitToSegmentId)
                this.fitToSegmentId = fitToSegmentId;
            end
            
            if exist('fixSegmentId', 'var') && ~isempty(fixSegmentId)
                this.fixSegmentId = fixSegmentId;
            end
        end
        
        function [fFixed, fourierFit, waveFVector, shift] = adjust(this, fToFix, zToFix, fFit, zFit, k)
        % Adjusts long-wavelength disturbances to the baseline
        
            % Fit wave function
            fFitSegment = util.croparr(fFit, this.fittingRangeParams.a, this.fittingRangeParams.b);
            zFitSegment = util.croparr(zFit, this.fittingRangeParams.a, this.fittingRangeParams.b);
            fourierFit = fit(zFitSegment(:), fFitSegment(:), ['fourier' num2str(this.fourierSeriesOrder)]);

            % Generate wave vector for the analyzed segment
            waveFVector = this.calcWaveVector(zToFix, fourierFit);
            shift = fourierFit.a0;
            
            % debug plot
%             if false && Simple.isdebug()
%                 figure();
%                 plot(zFitSegment,fFitSegment,zToFix,fToFix,zToFix,waveFVector+fourierFit.a0,zToFix,fToFix-waveFVector);
%                 legend('Fit To...', 'Retract', 'Fit Wave', 'Retract Signal');
%                 title('Fourier Fit Baseline');
%             end

            fFixed = fToFix - waveFVector;
        end
        
        function waveFVector = calcWaveVector(this, z, fourierFit)
            waveFVector = zeros(1, length(z));
            for i = 1:this.fourierSeriesOrder
                a = fourierFit.(['a' num2str(i)]);
                b = fourierFit.(['b' num2str(i)]);
                waveFVector = waveFVector + a*cos(i*z*fourierFit.w) + b*sin(i*z*fourierFit.w);
            end
        end
    end 
end