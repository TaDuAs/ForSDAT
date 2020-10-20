classdef DataSmoothingAdjuster < handle
    %DATASMOOTHINGADJUSTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private, Constant)
        METHOD_HANDLES = {...
            'sgolay', @ForSDAT.Core.Adjusters.DataSmoothingAdjuster.smoothHandle;... Stavinsky-Golay, default
            'moving', @ForSDAT.Core.Adjusters.DataSmoothingAdjuster.smoothHandle;... Moving Average
            'lowess', @ForSDAT.Core.Adjusters.DataSmoothingAdjuster.smoothHandle;...
            'loess', @ForSDAT.Core.Adjusters.DataSmoothingAdjuster.smoothHandle;...
            'rlowess', @ForSDAT.Core.Adjusters.DataSmoothingAdjuster.smoothHandle;...
            'rloess', @ForSDAT.Core.Adjusters.DataSmoothingAdjuster.smoothHandle;...
            'movmedian', @ForSDAT.Core.Adjusters.DataSmoothingAdjuster.smoothDataHandle;... 'moving median'
            'gaussian', @ForSDAT.Core.Adjusters.DataSmoothingAdjuster.smoothDataHandle...
            };
        METHOD_MAP = containers.Map(ForSDAT.Core.Adjusters.DataSmoothingAdjuster.METHOD_HANDLES(:,1), ForSDAT.Core.Adjusters.DataSmoothingAdjuster.METHOD_HANDLES(:,2));
    end
    
    properties (Constant)
        ALGORITHMS = ForSDAT.Core.Adjusters.DataSmoothingAdjuster.METHOD_HANDLES(:,1);
    end
    
    properties
        algorithm = 'sgolay';
        span = 7;
        degree = 3;
        edgeNonSmoothRange = [];
        useXValues = true;
    end
    
    methods % Property accessors
        function value = get.algorithm(this)
            value = this.algorithm;
        end
        function set.algorithm(this, value)
            if ~ForSDAT.Core.Adjusters.DataSmoothingAdjuster.METHOD_MAP.isKey(value)
                error(['Specified algorithm ''' value '''not supported']);
            end
            this.algorithm = value;
        end
    end
    
    methods (Static, Access=private) % smoothing handles
        function smoothed = smoothHandle(this, x, y)
            smoothed = util.invokeOptionalParams(...
                    @smooth,...
                    util.prepOptionalParams({util.cond(this.useXValues, x, []), y, this.span, this.algorithm, this.degree},...
                                   num2cell(1:5),...
                                   {false, true, false, false, false}));
        end
        
        function smoothed = smoothDataHandle(this, x, y)
            % smoothdata is only available starting Matlab R2017a, for
            % older versions, use smoothts.
            % Determine the existance of smoothdata once per matlab session
            persistent useSmoothData;
            if isempty(useSmoothData)
                % I don't know what type of file i should check for
                useSmoothData = exist('smoothdata', 'file') > 0;
            end
            
            if useSmoothData
                smoothed = smoothdata(y, this.algorithm, this.span);
            else
                if strcmp(this.algorithm, 'gaussian')
                    smoothed = smoothts(y, 'g', this.span);
                else
                    error(['Smoothing algorithm ''' this.algorithm ''' not supported']);
                end
            end
        end
    end
    
    methods
        function name = name(this)
            name = 'Smoothing';
        end
        
        function this = DataSmoothingAdjuster(span, algorithm, degree, edgeNonSmoothRange, useXValues)
            if exist('span', 'var')
                this.span = span;
            end
            if exist('algorithm', 'var')
                this.algorithm = algorithm;
            end
            
            if strcmp(this.algorithm, 'sgolay')
                if exist('degree', 'var')
                    this.degree = degree;
                end
            else
                this.degree = [];
            end
            
            if exist('edgeNonSmoothRange', 'var') && ~isempty(edgeNonSmoothRange)
                this.edgeNonSmoothRange = edgeNonSmoothRange;
            end
            
            if exist('useXValues', 'var') && ~isempty(useXValues) && islogical(useXValues)
                this.useXValues = useXValues;
            end
        end
        
        function [z, f] = adjust(this, z, f)
            
            smoothingFunction = ForSDAT.Core.Adjusters.DataSmoothingAdjuster.METHOD_MAP(this.algorithm);
            fSmoothed = smoothingFunction(this, z, f);
            
            if ~isempty(this.edgeNonSmoothRange)
                startRange = 1:this.edgeNonSmoothRange;
                n = length(f);
                endRange = n-this.edgeNonSmoothRange+1:n;
                i = [startRange endRange];
                fSmoothed(i) = f(i);
            end
            f = fSmoothed;
            
            % nRows, nCols
            [nFr, nFc] = size(f);
            [nZr, nZc] = size(z);
            
            if (nFc ~= nZc)
                f = f';
            end
        end
    end
    
end

