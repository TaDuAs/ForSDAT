app = ForSDAT.Application.startgui();

controller = app.MainView.Session.getController('ForceSpecAnalysisController');

controller.setProject(gen.localPath('ExampleProject.xml'));