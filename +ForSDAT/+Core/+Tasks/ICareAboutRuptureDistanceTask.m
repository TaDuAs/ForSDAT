classdef (Abstract) ICareAboutRuptureDistanceTask < handle
    properties
        rupturesChannel = 'Rupture';
    end
    
    methods (Abstract)
        chnl = getChannelData(this, data, channelName, isStrict);
    end
    
    methods
        function ruptureDist = getRuptureDistances(this, data)
            ruptures = this.getChannelData(data, this.rupturesChannel, false);
            if ~isempty(ruptures)
                ruptureDist = ruptures.distance;
            else
                ruptureDist = 0;
            end
        end
    end
end

