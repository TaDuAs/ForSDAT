classdef RawDataAnalyzer < handle & mfc.IDescriptor
    properties (SetObservable)
        pipeline lists.Pipeline;
        settings = [];
    end
    
    methods % meta data
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'pipeline'};
            defaultValues = {'pipeline', []};
        end
    end
    
    methods
        function this = RawDataAnalyzer(pipeline)
            if nargin >= 1 && ~isempty(pipeline)
                this.pipeline = pipeline;
            else
                this.pipeline = lists.Pipeline();
            end
        end
        
        function init(this, settings)
            this.settings = settings;
            this.pipeline.init(settings);
        end
        
        function this = addTask(this, task)
            this.pipeline.addTask(task);
            
        end
        
        function task = getTask(this, i)
            task = this.pipeline.getTask(i);
        end
        
        function [data] = analyze(this, curve, segmentId)
            segment = curve.getSegment(segmentId);
            data = struct();
            
            % Get segment data
            frc = segment.force;
            dist = segment.distance;
            
            for i = 1:length(curve.segments)
                seg = curve.getSegment(i);
                
                if ~isempty(seg.force)
                    data.(seg.name) = struct('Distance', seg.distance, ...
                                             'Force', seg.force);
                end
            end
            
            data.Force = frc;
            data.Distance = dist;
            
            data.Setup.retractSpeed = this.settings.measurement.speed;
            data.Setup.samplingRate = this.settings.measurement.samplingRate;
            linker = mvvm.getobj(this.settings, 'measurement.linker', [], 'nowarn');
            if ~isempty(linker) 
                data.Setup.linker = linker;
            else
                data.Setup.linker = chemo.PEG(0);
            end
            mol = mvvm.getobj(this.settings, 'measurement.molecule', [], 'nowarn');
            if ~isempty(mol) 
                data.Setup.molecule = mol;
            else
                data.Setup.molecule = chemo.PEG(0);
            end
            data.Setup.noiseAnomally = this.settings.measurement.noiseAnomally;
            
            data.BatchPosition.x = segment.xPosition;
            data.BatchPosition.y = segment.yPosition;
            data.BatchPosition.i = segment.curveIndex;
            
            data.Cantilever = [];
            if isprop(segment, 'springConstant')
                data.Cantilever.springConstant = segment.springConstant;
                data.Cantilever.springConstantEstimated = false;
            end
            if isprop(segment, 'sensitivity')
                data.Cantilever.sensitivity = segment.sensitivity;
            end
            
            data = this.pipeline.run(data);
        end
        
        function plotData(this, fig, data, taskIndex, extras)
            if nargin < 4 || isempty(taskIndex)
                taskIndex = this.pipeline.tasksNumber();
            end
            
            task = this.pipeline.getTask(taskIndex);
            if nargin < 5
                task.plotData(fig, data);
            else
                task.plotData(fig, data, extras);
            end
        end
    end
end

