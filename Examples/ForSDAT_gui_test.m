mvvm.AppManager.clear();

app = ForSDAT.Application.startgui();

% load example project
procController = app.MainView.Session.getController('ProcessSetupController'); 
procController.setProject(gen.localPath('ExampleProject.xml'));

% load example data
procController.loadBatchOfForceCurves(gen.localPath('Data'));

% start example project
analysisController = app.MainView.Session.getController('ForceSpecAnalysisController'); 
analysisController.start();