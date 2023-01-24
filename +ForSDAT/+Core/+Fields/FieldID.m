classdef FieldID
    properties
        Name (1,:) char;
        Type ForSDAT.Core.Fields.FieldType = ForSDAT.Core.Fields.FieldType.None;
    end
    
    methods
        function this = FieldID(type, name)
            if nargin >= 1
                this.Type = type;
            end
            if nargin >= 2
                this.Name = name;
            end
        end
        
        function tf = eq(A, B)
            tf = reshape(eq([A.Type], [B.Type]) & strcmp({A.Name}, {B.Name}), size(A));
        end
        
        function tf = ne(A, B)
            tf = ~eq(A, B);
        end
        
        function B = sort(A)
            types = double([A.Type]);
            names = {A.Name};
            [~, i] = sortrows([num2cell(types(:)), names(:)], [1, 2]);
            
            B = A(i);
        end
        
        function s = tostring(A)
            s = strcat(arrayfun(@char, [A.Type], 'UniformOutput', false), ' - ', {A.Name});
            if numel(A) == 1
                s = s{1};
            end
        end
    end
end

