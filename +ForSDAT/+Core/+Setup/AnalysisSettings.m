classdef AnalysisSettings
    properties
        Measurement ForSDAT.Core.Setup.MeasurementSetup = ForSDAT.Core.Setup.MeasurementSetup();
        NoiseAnomally ForSDAT.Core.NoiseAnomally = ForSDAT.Core.NoiseAnomally(2, 1000, 2048);
        FOOM util.OOM = util.OOM.Pico;
        ZOOM util.OOM = util.OOM.Nano;
    end
end

