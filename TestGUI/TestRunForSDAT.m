app = ForSDAT.Application.startgui();
session = app.MainView.Session;
controller = session.getController('ForceSpecAnalysisController');
serializer = session.IocContainer.get('mxml.XmlSerializer');

localPath = gen.localPath();

% load data accessor
dataAccessor = serializer.load(fullfile(localPath, 'jpkDataLoader.xml'));
controller.setDataAccessor(dataAccessor);
controller.AnalyzedSegment = 'retract';

% load analyzer
analyzer = serializer.load(fullfile(localPath, 'rawAnalyzer.xml'));
controller.setRawAnalyzer(analyzer);

% load cooked data analyzer
cookedAnalyzer = serializer.load(fullfile(localPath, 'cookedAnalyzer.xml'));
controller.setCookedAnalyzer(cookedAnalyzer);

% load default settings
settings = serializer.load(fullfile(localPath, 'defaultSettings.xml'));
controller.setSettings(settings);
