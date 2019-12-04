n = 10000;
ni = 100000000;

cook = SMICookedDataAnalyzer(Simple.App.App.getRepository(), '', []);

data = mgr.analyze(fdc, 'retract');
%%
tic
for i = 1:n
    cook.acceptData(data, num2str(i+ni));
end
toc

