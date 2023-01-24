classdef AnalyzedFDCData < mfc.IDescriptorStruct
    
    properties
        f = [];         % force
        energy = [];    % energy
        z = [];         % distance
        slope = [];     % fd-slope
        lr = [];        % loading rate
        noise = [];     % noise amplitude - for force error
        posx = -1;      % AFM head lateral position X
        posy = -1;      % AFM head lateral position Y
        posi = -1;      % AFM head lateral position index in batch
        file = '';      % fd-curve file name
        
        % scfs stuff
        ruptureForce = [];          % magnitude of each detected rupture event 
        ruptureDistance = [];       % distance of each detected rupture event
        nRuptures = 0;              % number of detected single rupture events
        maxAdhesionDistance = [];   % distance of final detachment event
    end
    
    properties (Access=private)
        isEmpty = false;
    end
    
    methods % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'f', 'z', 'slope', 'file', 'lr', 'noise', 'posx', 'posy', 'posi'};
            defaultValues = {'f', [], 'z', [], 'slope', [],...
                'file', '',...
                'lr', [], 'noise', [],...
                'posx', [], 'posy', [], 'posi' [],};
        end
    end

    methods
        function this = AnalyzedFDCData(f, z, slope, file, lr, noise, x, y, i)
            if nargin < 1
                return;
            end
            
            this.f = f;
            this.z = z;
            this.slope = slope;
            this.file = file;
            if (nargin > 4)
                this.lr = lr;
            end
            if nargin > 5
                this.noise = noise;
            end
            if (nargin == 7)
                lenPos = length(x);
                if (lenPos == 3)
                    this.posx = x(1);
                    this.posy = x(2);
                    this.posi = x(3);
                elseif (lenPos == 2)
                    this.posx = x(1);
                    this.posy = x(2);
                else
                    error('Specify both x & y');
                end
            elseif (nargin > 7)
                this.posx = x;
                this.posy = y;
                this.posi = i;
            end
        end
        
        function result = ismember(a, b)
            if isempty(a) || isempty(b) || ~any([a.isEmpty] == 0) || ~any([b.isEmpty] == 0)
                result = zeros(length(a));
            else
                result = ismember({a.file}, {b.file});
            end
        end
        
        function result = eq(a,b)
            result = ((isempty(a) || a.isEmpty) && (isempty(b) || b.isEmpty)) || strcmp(a.file, b.file);
        end
        
        function result = ne(a,b)
            result = ~(a.eq(b));
        end
    end
    
    methods (Static)
        function val = createEmpty()
            val = ForSDAT.Core.AnalyzedFDCData([],[],'',[]);
            val.isEmpty = true;
        end
    end
    
end

