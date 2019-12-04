classdef ForceDistanceSegment < handle
    
    properties
        
        index = -1;         % index of segment
        name = '';          % segment name
        springConstant = [];% AFM cantilever spring constant
        sensitivity = [];   % AFM cantilever sensitivity
        force = [];         % force data array
        distance = [];      % distance data array
        time = [];          % time from segment start
        xPosition = [];     % position in image
        yPosition = [];     % position in image
        curveIndex = [];    % index of the curve in the batch
    end
    
    methods
        function this = ForceDistanceSegment(index, name, springConstant, sensitivity, force, distance, time, xPos, yPos, curveIndex)
            % Send everything or nothing,
            % this is basically for the factory builder
            if nargin >= 10
                this.index = index;
                this.name = name;
                this.springConstant = springConstant;
                this.sensitivity = sensitivity;
                this.force = force;
                this.distance = distance;
                this.time = time;
                this.xPosition = xPos;
                this.yPosition = yPos;
                this.curveIndex = curveIndex;
            end
        end
    end
end

