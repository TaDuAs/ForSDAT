classdef CropCurveView < mvvm.view.ComponentView
    
    properties
        Property1
    end
    
    methods
        function this = CropCurveView(parent, ownerView, varargin)
            this@mvvm.view.ComponentView(parent, 'OwnerView', ownerView, 'BoxType', @sui.FlowBox, varargin{:});
        end
    end
    
    methods (Access=protected)
        function initializeComponents(this)
            initializeComponents@mvvm.view.ComponentView(this);
            
            this.OomValues = [util.OOM.Normal, util.OOM.Mili, util.OOM.Micro, util.OOM.Nano, util.OOM.Pico, util.OOM.Femto];
            prefixes = arrayfun(@getPrefix, this.OomValues, 'UniformOutput', false);
            
            % set container properties
            container = this.getContainerHandle();
            container.Spacing = 10;
            container.Padding = 10;
                        
            % Force OOM
            this.FoomLabel = uicontrol(container, 'Style', 'text', 'String', 'Force Units:', 'Position', [0 0 100 25], ...
                'HorizontalAlignment', 'left');
            this.FoomDropdown = uicontrol(container, 'Style', 'popupmenu', 'String', strcat(prefixes, 'N'), 'Position', [0 0 100 25]);
            mvvm.AdaptationBinder(...
                'Project.CurrentEditedTask.adjuster.FOOM', ...
                this.FoomDropdown, ...
                'Value', ...
                mvvm.FunctionHandleDataAdapter(@this.oomModel2Gui, @this.oomGui2Model), ...
                'Event', 'Callback');
            sui.LineBreak('Parent', container);
            
            % Distance OOM
            this.ZoomLabel = uicontrol(container, 'Style', 'text', 'String', 'Distance Units:', 'Position', [0 0 100 25], ...
                'HorizontalAlignment', 'left');
            this.ZoomDropdown = uicontrol(container, 'Style', 'popupmenu', 'String', strcat(prefixes, 'm'), 'Position', [0 0 100 25]);
            mvvm.AdaptationBinder(...
                'Project.CurrentEditedTask.adjuster.ZOOM', ...
                this.FoomDropdown, ...
                'Value', ...
                mvvm.FunctionHandleDataAdapter(@this.oomModel2Gui, @this.oomGui2Model), ...
                'Event', 'Callback');
            sui.LineBreak('Parent', container);
        end
    end
    
end

