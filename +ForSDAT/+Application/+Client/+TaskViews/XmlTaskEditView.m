classdef XmlTaskEditView < mvvm.view.ComponentView
    properties
        Serializer mxml.ISerializer = mxml.XmlSerializer.empty();
        MXmlTextBox;
        MXmlBinder;
    end
    
    methods
        function this = XmlTaskEditView(parent, ownerView, serializer)
            this@mvvm.view.ComponentView(parent, 'OwnerView', ownerView, 'Serializer', serializer);
        end
    end
    
    methods (Access=protected)
        function prepareParser(this, parser)
            prepareParser@mvvm.view.ComponentView(this, parser);
            
            addOptional(parser, 'Serializer', mxml.XmlSerializer.empty());
        end
        
        function extractParserParameters(this, parser)
            extractParserParameters@mvvm.view.ComponentView(this, parser);
            
            this.Serializer = parser.Results.Serializer;
        end
        
        function initializeComponents(this)
            this.MXmlTextBox = uicontrol(this.getContainerHandle(), ...
                'Style', 'edit', ...
                'Units', 'norm', 'Position', [0 0 1 1],...
                'Min', 0, 'Max', 100);
            this.MXmlBinder = mvvm.AdaptationBinder('Project.CurrentEditedTask', this.MXmlTextBox, 'String',...
                mvvm.FunctionHandleDataAdapter(@this.task2MXml, @this.mxml2Task),...
                'Event', 'KeyRelease',...
                'UpdateDelay', 0.4);
        end
        
        function text = task2MXml(this, task)
            if isempty(task)
                text = '';
            else
                text = this.Serializer.serialize(task);
            end
        end
        
        function task = mxml2Task(this, text)
            task = this.Serializer.deserialize(text);
        end
    end
end

