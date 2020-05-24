classdef JpkDelimiterValuesExporterImporter < dao.DelimiterValuesDataExporter
    %JPKDELIMITERVALUESEXPORTERIMPORTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        zoom = util.OOM.Nano;
        foom = util.OOM.Pico;
    end
    
    methods
        
        function this = JpkDelimiterValuesExporterImporter(delimiter, zoom, foom)
            if nargin < 1; delimiter = []; end
            this@dao.DelimiterValuesDataExporter(delimiter);
            
            if nargin >= 2 && ~isempty(zoom)
                this.zoom = zoom;
            end
            if nargin >= 3 && ~isempty(foom)
                this.foom = foom;
            end
        end
        
        function data = load(this, path)
            baseInfo = load@DelimiterValuesDataExporter(this, path);

            if any(regexp(path, '.+\-steps.*'))
                forces = this.extractForceFromSteps(baseInfo);
                n = length(forces);
                distances = this.extractDistanceFromSteps(baseInfo);
                slope = this.extractSlopeFromSteps(baseInfo, n);
                lrArr = this.extractLRFromSteps(baseInfo, n);
            elseif any(regexp(path, '.+\-chainfits.*'))
                forces = this.extractForceFromChainFit(baseInfo);
                n = length(forces);
                distances = this.extractDistanceFromChainFit(baseInfo);
                slope = this.extractSlopeFromChainFit(baseInfo, n);
                lrArr = this.extractLRFromChainFit(baseInfo, n);
            end
            
            fileName = {baseInfo.Filename};
            
            data = repmat(ForSDAT.Core.AnalyzedFDCData, 1, n);
            for i = 1:n
                data(i) = ForSDAT.Core.AnalyzedFDCData(forces(i), distances(i), slope(i), fileName{i}, util.cond(isempty(lrArr), @() [], @() lrArr(i)));
            end
        end
        
        function f = extractForceFromSteps(this, data)
            f = [data.Step_Height_0x5BN0x5D] .* 10^(-this.foom);
        end
        
        function z = extractDistanceFromSteps(this, data)
            z = [data.Step_Position_0x5Bm0x5D] .* 10^(-this.zoom);
        end
        
        function s = extractSlopeFromSteps(this, data, n)
            s = zeros(1, n);
        end
        
        function lr = extractLRFromSteps(this, data, n)
            lr = [];
        end
        
        function f = extractForceFromChainFit(this, data)
            f = [data.Breaking_Force_0x5BN0x5D] .* 10^(-this.foom);
        end
        
        function z = extractDistanceFromChainFit(this, data)
            z = [data.X_Max_0x5Bm0x5D] .* 10^(-this.zoom);
        end
        
        function s = extractSlopeFromChainFit(this, data, n)
            s = zeros(1, n);
        end
        
        function lr = extractLRFromChainFit(this, data, n)
            lr = [data.Critical_Loading_Rate_0x5BN0x2Fs0x5D];
        end
    end
    
end

