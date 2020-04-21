classdef OOMAdjusterView < mvvm.view.ComponentView
    properties
        OomValues Simple.Math.OOM;
        FoomDropdown;
        FoomLabel;
        ZoomDropdown;
        ZoomLabel;
    end
    
    methods
        function this = OOMAdjusterView(parent, ownerView, varargin)
            this@mvvm.view.ComponentView(parent, 'OwnerView', ownerView, 'BoxType', @sui.FlowBox, varargin{:});
        end
    end
    
    methods (Access=protected)
        function initializeComponents(this)
            initializeComponents@mvvm.view.ComponentView(this);
            
            this.OomValues = [Simple.Math.OOM.Normal, Simple.Math.OOM.Mili, Simple.Math.OOM.Micro, Simple.Math.OOM.Nano, Simple.Math.OOM.Pico, Simple.Math.OOM.Femto];
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
    
    methods (Access=private)
        function model = oomGui2Model(this, value)
            if isempty(value); value = 1; end

            model = this.OomValues(value);
        end
        
        function value = oomModel2Gui(this, model)
            if isempty(model)
                value = 1;
            else
                value = find(this.OomValues == model);
            end
        end
    end
end

