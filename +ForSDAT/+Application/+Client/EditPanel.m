classdef EditPanel < mvvm.view.ComponentView
    %EDITPANEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
%         SubViewsBinder mvvm.Repeater;
        Frame sui.ViewSwitch;
        CurrentFrameBinder mvvm.Binder;
        Serialzier mxml.XmlSerializer;
    end
    
    methods
        function this = EditPanel(parent, parentView, messenger, bindingManager, modelProvider, viewManager, serialzier)
            this@mvvm.view.ComponentView(parent, 'OwnerView', parentView, ...
                'Messenger', messenger, 'BindingManager', bindingManager,...
                'BoxType', @uix.ScrollingPanel,...
                'ModelProvider', modelProvider,...
                'ViewManager', viewManager);
            
            this.Serialzier = serialzier;
            
            this.Messenger.register(ForSDAT.Application.AppMessages.PreEditedTaskChange, @this.editedTaskChanging);
        end
        
        function delete(this)
            delete(this.CurrentFrameBinder);
            this.CurrentFrameBinder = mvvm.Binder.empty();
            delete(this.Frame);
            this.Frame = sui.ViewSwitch.empty();
            this.Serialzier = mxml.XmlSerializer.empty();
        end
    end
    
    methods (Access=protected)
        function initializeComponents(this)
            initializeComponents@mvvm.view.ComponentView(this);
            
%             this.SubViewsBinder = mvvm.Repeater('Project.RawAnalyzer.pipeline', this.getContainerHandle(), ...
%                 ForSDAT.Application.Client.EditSubViewTemplate(this, this.ViewManager));
            this.Frame = sui.ViewSwitch('OwnerView', this, 'Parent', this.getContainerHandle());
            this.CurrentFrameBinder = mvvm.Binder('Project.CurrentEditedTask.name', this.Frame, 'ActiveViewId',...
                'BindingManager', this.BindingManager);
            
            % One day this should be passed over to some app-map of sorts,
            % or at least a proper factory
            this.Frame.add("OOM Adjuster", @ForSDAT.Application.Client.TaskViews.OOMAdjusterView);
            this.Frame.add("Baseline", @this.mxmlTaskEditor);
            this.Frame.add("Chain Fit", @this.mxmlTaskEditor);
            this.Frame.add("Contact Point Detector", @this.mxmlTaskEditor);
            this.Frame.add("Interaction Window", @this.mxmlTaskEditor);
            this.Frame.add("Rupture Detector", @this.mxmlTaskEditor);
            this.Frame.add("Smoothing", @this.mxmlTaskEditor);
            this.Frame.add("Specific Interaction Detector", @this.mxmlTaskEditor);
            this.Frame.add("Tip Height Adjuster", @this.mxmlTaskEditor);
            this.Frame.add("Adhesion Energy", @this.mxmlTaskEditor);
            this.Frame.add("Adhesion Force", @this.mxmlTaskEditor);
            this.Frame.add("Oscillatory Baseline Adjuster", @this.mxmlTaskEditor);
        end
        
        function view = mxmlTaskEditor(this, container, ownerView)
            view = ForSDAT.Application.Client.TaskViews.XmlTaskEditView(container, ownerView, this.Serialzier);
        end
        
        function editedTaskChanging(this, message)
            newTask = message.Data;
            if ~isempty(newTask) && ~isempty(this.Frame) ...
                    && ~isempty(this.Frame.ActiveViewId)...
                    && ~isempty(this.Frame.ActiveView) ...
                    && ~strcmp(newTask.name, this.Frame.ActiveViewId.ID)
                this.Frame.ActiveView.sleep();
            end
        end
    end
end

