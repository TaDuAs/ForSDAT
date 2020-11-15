classdef FieldType < double
    enumeration
        None (0);
        
        % Data fields
        Time (1);
        Distance (2);
        Force (4);
        Rupture (8);
        Model (16);
        SMI (32);
        Adhesion (64);
        
        % Meta data fields
        DecisionFlag (128);
        Baseline (256);
        Contact (512)
        Noise (1024);
        Threshold (2048);
        Setup (4096);
        Miscellaneous (8192);
    end
    
    methods
        function tf = check(this, fieldType)
            tf = bitget(this, log2(fieldType)+1);
        end
        
        function this = add(this, fieldType)
            this = bitor(this, fieldType);
        end
        
        function this = remove(this, fieldType)
            this = bitset(this, log2(fieldType)+1, 0);
        end
    end
end

