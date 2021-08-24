app = ForSDAT.Application.startgui();

% load example project
% controller = app.MainView.Session.getController('ForceSpecAnalysisController'); 

% load example data
procController = app.MainView.Session.getController('ProcessSetupController'); 
procController.setProject(gen.localPath('ExampleProject.xml'));
procController.loadBatchOfForceCurves(gen.localPath('Data'));