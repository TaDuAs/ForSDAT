classdef OOMAdjusterView
    %OOMADJUSTERVIEW Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        oomValues Simple.Math.OOM;
        
        container;
        foomDropdown;
        foomLabel;
        zoomDropdown;
        zoomLabel;
    end
    
    methods
        function this = OOMAdjusterView(parent)            
            this.initializeComponents(parent);
        end
        
        function initializeComponents(this, parent)
            this.oomValues = [Simple.Math.OOM.Normal, Simple.Math.OOM.Mili, Simple.Math.OOM.Micro, Simple.Math.OOM.Nano, Simple.Math.OOM.Pico, Simple.Math.OOM.Femto];
            prefixes = arrayfun(@getPrefix, this.oomValues, 'UniformOutput', false);
            
            this.container = sui.FlowBox('Parent', parent, 'Spacing', 10, 'Padding', 10);
            
            function value = oomModel2Gui(model)
                if isempty(model)
                    value = 1;
                else
                    value = find(this.oomValues == model);
                end
            end
            function model = oomGui2Model(value)
                if isempty(value); value = 1; end
                
                model = this.oomValues(value);
            end
            
            this.foomLabel = uicontrol(this.container, 'Style', 'text', 'String', 'Force Units:', 'Position', [0 0 100 25], ...
                'HorizontalAlignment', 'left');
            this.foomDropdown = uicontrol(this.container, 'Style', 'popupmenu', 'String', strcat(prefixes, 'N'), 'Position', [0 0 100 25]);
            mvvm.AdaptationBinder(...
                'currentEditedTask.adjuster.FOOM', ...
                this.foomDropdown, ...
                'Value', ...
                mvvm.FunctionHandleDataAdapter(@oomModel2Gui, @oomGui2Model), ...
                'Event', 'Callback');
            sui.LineBreak('Parent', this.container);
            
            this.zoomLabel = uicontrol(this.container, 'Style', 'text', 'String', 'Distance Units:', 'Position', [0 0 100 25], ...
                'HorizontalAlignment', 'left');
            this.zoomDropdown = uicontrol(this.container, 'Style', 'popupmenu', 'String', strcat(prefixes, 'm'), 'Position', [0 0 100 25]);
            mvvm.AdaptationBinder(...
                'currentEditedTask.adjuster.ZOOM', ...
                this.foomDropdown, ...
                'Value', ...
                mvvm.FunctionHandleDataAdapter(@oomModel2Gui, @oomGui2Model), ...
                'Event', 'Callback');
            sui.LineBreak('Parent', this.container);
        end
    end
end

