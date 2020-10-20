% start ForSDAT application
app = ForSDAT.Application.ForSDATApp.ensureAppLoaded('console');
util.disableWarnings();

% start session and activate controller
[~, session] = app.startSession();
controller = session.getController('ForceSpecAnalysisController');
controller.setProject(gen.localPath('ExampleProject.xml'));

% load an existing experiments repository
controller.Project.CookedAnalyzer.ExperimentRepositoryDAO.RepositoryPath = gen.localPath('Repos');
controller.loadExperimentRepository('Example02');
fig = figure(99);
fig.Position = [100 100 800 600];
[params, p, R2] = controller.Project.CookedAnalyzer.bellEvansPlot();
disp(params);