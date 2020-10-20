classdef InteractionWindowSMIFilter < handle
    %INTERACTIONWINDOWSMIFILTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        molecule;
        linker;
        noiseAnomally;
        filterType char {mustBeMember(filterType, {'all', 'last'})} = 'all';
        
        acceptedRange;
        startAt;
        endAt;
    end
    
    methods % Property Accessors
        function value = get.startAt(this)
            value = this.linker.backboneLength - this.acceptedRange;
        end
        
        function value = get.endAt(this)
            value = this.linker.backboneLength + this.acceptedRange + this.molecule.getSize();
        end
    end
    
    methods
        
        function this = InteractionWindowSMIFilter(acceptedRange)
            if nargin >= 1 && ~isempty(acceptedRange)
                this.acceptedRange = acceptedRange;
            end
        end
        
        function init(this, settins)
            this.molecule = mvvm.getobj(settins, 'Measurement.Probe.Molecule', chemo.PEG(0), 'nowarn');

            this.linker = mvvm.getobj(settins, 'Measurement.Probe.Linker', chemo.PEG(0), 'nowarn');
            
            this.noiseAnomally = settins.NoiseAnomally;
        end 
            
        function [lsRsRe, indexOfSpecificInteractionInRuptureEventsMatrix] = ...
                filter(this, frc, dist, ruptureEvents, noiseAmplitude, baselineThreshold)
            flaggedRuptureEvents = this.setFlagsByInteractionWindow(...
                frc,...
                dist,...
                ruptureEvents,...
                baselineThreshold);
            
            [lsRsRe, indexOfSpecificInteractionInRuptureEventsMatrix] = this.filterFlags(flaggedRuptureEvents);
        end
    end
    
    methods (Access=protected)
        
        function flaggedRuptureEvents = setFlagsByInteractionWindow(this, frc, dist, ruptureEvents, noiseAmplitude, baselineThreshold)
            
            % add validity flag
            flaggedRuptureEvents = [ruptureEvents; ones(1, size(ruptureEvents, 2))];
            
            % Filter noise anomallies
            flaggedRuptureEvents(end, :) = flaggedRuptureEvents(end, :) & ...
                flaggedRuptureEvents(2, :) - flaggedRuptureEvents(1, :) + 1 >= this.noiseAnomally.DataPoints;
            
            % Linker window
            flaggedRuptureEvents(end, :) = flaggedRuptureEvents(end, :) & ...
                dist(flaggedRuptureEvents(2, :)) >= this.startAt &...
                dist(flaggedRuptureEvents(2, :)) <= this.endAt;
            
            % only the last interaction within the linker window
            switch this.filterType
                case 'last'
                    temp = flaggedRuptureEvents(:, flaggedRuptureEvents(end,:) == 1);
                    if ~isempty(temp)
                        lastRupture = max(temp(2, :));
                        flaggedRuptureEvents(end, :) = flaggedRuptureEvents(end, :) & flaggedRuptureEvents(2,:) == lastRupture;
                    end
            end
        end
        
        function [lsRsRe, indexOfSpecificInteractionInRuptureEventsMatrix] = filterFlags(this, flaggedRuptureEvents)
            % Only keep the last flagged interaction
%             [~, i] = sortrows(flaggedRuptureEvents', [-4, -2]);
%             if isempty(i) || (flaggedRuptureEvents(4, i(1)) == 0)
%                 indexOfSpecificInteractionInRuptureEventsMatrix = [];
%                 lsRsRe = [];
%             else
%                 indexOfSpecificInteractionInRuptureEventsMatrix = i(1);
%                 lsRsRe = flaggedRuptureEvents(1:3, i(1));
%             end


            [lsRsRe, indexOfSpecificInteractionInRuptureEventsMatrix] = ForSDAT.Core.Ruptures.filterFlagsMatrix(flaggedRuptureEvents, 4, -2);
        end
    end
    
end

