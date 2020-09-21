classdef ForceDistanceCurve < handle
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        segments = ForSDAT.Core.ForceDistanceSegment.empty();
    end
    
    methods
        function this = ForceDistanceCurve(segments)
            if nargin >= 1
                this.segments = segments;
            end
        end
        
        function segment = getSegmentByName(this, name)
            segment = [];
            for i = 1:length(this.segments)
                if strcmp(this.segments(i).name, name)
                    segment = this.segments(i);
                    break;
                end
            end
            
            if isempty(segment)
                error(['No segment with specified name ' name ' exists.']);
            end
        end
        
        function segment = getSegment(this, id)
            if ischar(id)
                segment = this.getSegmentByName(id);
            else
                if isempty(id) || isnan(id) || id > length(this.segments) || id < 1
                    error(['No segment with id ' num2str(id) ' exists.']);
                else
                    segment = this.segments(id);
                end
            end
        end
        
        function plotCurve(this, fig, type)
            if nargin < 2 || isempty(fig)
                fig = figure();
            end
            if isa(fig, 'matlab.graphics.axis.Axes')
                subplot(fig);
                plotAxes = fig;
            else
                % plot everything in same axes
                plotAxes = axes('Parent',fig);
            end
            hold(plotAxes,'on');
            if nargin < 3 || isempty(type)
                type = 'd';
            end
            
            % plot all segments
            for i = 1:length(this.segments)
                seg = this.segments(i);
                frc = seg.force;%this.filterForce(seg);
                if strcmpi(type, 'time')
                    x = seg.time;
                    xAxesTitle = 'Time (s)';
                else
                    x = seg.distance;%this.filterDistance(seg);
                    xAxesTitle = 'Tip Height (nm)';
                end
                plot(x, frc, 'DisplayName', seg.name);
            end
            
            set(gca(), 'FontSize', 18);
            xlabel(xAxesTitle, 'FontSize', 24);
            ylabel('Force (N)', 'FontSize', 24);
            
            % hold off
            hold(plotAxes,'off');

            % Create legend
            legend(plotAxes,'show');
        end
%         
%         function fdc = applyFilter(this, filter)
%             fdc = this;
%             this.filters = [this.filters, filter];
%             this.clearSegmentsFilters();
%         end
%         
%         function fdc = clearFilters(this)
%             fdc = this;
%             this.filters = [];
%             this.clearSegmentsFilters();
%         end
%         
%         function clearSegmentsFilters(this)
%             for i = 1:length(this.segments)
%                 this.segments(i).clearFilter();
%             end
%         end
    end
    
end

