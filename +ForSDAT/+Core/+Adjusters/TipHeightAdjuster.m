classdef TipHeightAdjuster < handle
    %TIPHEIGHTADJUSTER Summary of this class goes here
    %   Detailed explanation goes 
    
    properties
        springConstant = []; % N/m
        foom = Simple.Math.OOM.Normal;
        doom = Simple.Math.OOM.Normal;
        smoothDistance = true;
    end
    
    methods
        function this = TipHeightAdjuster(k, foom, doom)
            % Initializes a new instance of the TipHeightAdjuster
            % TipHeightAdjuster():
            %   No specified spring constant, will use the spring constant
            %   from curve data
            % TipHeightAdjuster(k):
            %   specified spring constant has the same units as the force
            %   and distance vectors
            % TipHeightAdjuster(k, foom, doom):
            %   specified spring constant is in N/m. specified force and
            %   distance OOMs are used to cast the spring constant into the
            %   right units (pN, nN, uN, nm, mm, m, etc.)
            
            if exist('k', 'var') && ~isempty(k)
                this.springConstant = k;
            end
            
            if exist('foom', 'var') && ~isempty(foom)
                this.foom = foom;
            end
            if exist('doom', 'var') && ~isempty(doom)
                this.doom = doom;
            end
        end
        
        function [z, f] = adjust(this, z, f, k, isKAdjusted, contactPointIdx)
            if ~isempty(this.springConstant)
                k = this.adjustK(this.springConstant);
            elseif nargin < 5 || ~isKAdjusted
                k = this.adjustK(k);
            end
            
            z = z + (f/k);
            
            if this.smoothDistance
                z = sort(z);
                
                if nargin >= 6 && ~isempty(contactPointIdx)
                    z = z - z(contactPointIdx);
                end
            end
        end
        
        function k = adjustK(this, k)
            k = k * 10^(this.doom-this.foom);
        end
    end
    
end

