classdef Direction < double
    enumeration
        Backward (-1),
        Forward (1)
    end
    
    methods
        function pos = lastPosition(dir, arr)
            switch dir
                case util.Direction.Backward
                    pos = 1;
                case util.Direction.Forward
                    pos = numel(arr);
                otherwise
                    pos = 1;
            end
        end
    end
end

