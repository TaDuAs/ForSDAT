% Monty Hall Problem demonstrated via the Monte Carlo technique
% http://en.wikipedia.org/wiki/Monty_Hall_problem
%
% Suppose you're on a game show, and you're given the choice of three doors: 
% Behind one door is a new car; behind the others, goats. 
% You pick a door, say Door #1, but the door is not opened yet.
% Then the host, who knows what's behind the doors, 
% opens another door, say Door #3, which reveals a goat. 
% He then asks you, "Do you want to change your selection?",
% in other words, change your selection from Door #1 to Door #2.
% Is it to your advantage to switch your choice?
%
% Most people would say it does not improve you odds of winning
% if you switch doors, since there is a 1/3 probability that
% a particular door hides the car, no matter which door it is.
% The correct answer is yes, it would be to your advantage to switch.
%
% Initially you have a 33% chance of picking the correct door.
% That means there is a 67% chance the "winning" door is
% one of the doors that you didn't pick.  No matter how many other doors
% the host reveals, there is still a 67% chance the winning door is
% one of the doors you didn't pick.  In the case of 3 doors,
% you didn't pick two of them and when the host opened one of the two
% "other" doors, that left one "other" door and that door
% still has a 67% probability of being the winning door.
%
% Look at it another way, by using extremes.
% Let's say there are a million doors and you pick one.
% Your chance of picking the car are 1 in a million,
% and there is a 999,999 in a million chance that the winner is
% one of the other 999,999 doors.  Now the host, knowing which
% doors have goats reveals 999,998 "goat" doors, leaving only one
% other door closed.  Did your chance of picking the correct door
% suddenly increase way up to 50%?  No, of course not - 
% you still have a 1 in a million chance with your original choice of door.
% But there's a 999,999 in a million chance that the car is behind 
% that one, single, other door, so you should switch.
%
% This simulation creates 15,000 experiments.  At each experiment
% the winning door is picked at random and the contestant's door
% is chosen at random.  You can specify whether to switch or not.
% To be more general, you can specify how many doors are there,
% and how many doors to reveal.  The Monte Carlo experiments are run
% and the final percentage is given, along with the theoretical probability.
clc;
clearvars;
workspace;

numberOfExperiments = 10000;
% Specify whether each experiment should be printed out to the command window.
showEachExperiment = false;

% Ask user for the number of doors.
defaultValue = 3;
titleBar = 'Enter an integer';
userPrompt = 'Enter the number of doors the contestant can choose from';
caUserInput = inputdlg(userPrompt, userPrompt, 1, {num2str(defaultValue)});
if isempty(caUserInput),return,end; % Bail out if they clicked Cancel.
numberOfDoors = round(str2num(cell2mat(caUserInput)));
% Check for a valid integer.
if isnan(numberOfDoors)
    % They didn't enter a number.  
    % They clicked Cancel, or entered a character, symbols, or something else not allowed.
    numberOfDoors = defaultValue;
    message = sprintf('I said it had to be an integer.\nI will use %d and continue.', numberOfDoors);
    uiwait(warndlg(message));
end

% Ask user for the number of doors to reveal, only applicable if there are more than 3 doors.
if numberOfDoors > 3
	defaultValue = numberOfDoors - 2;
	titleBar = 'Enter an integer';
	userPrompt = sprintf('Enter the number of doors to reveal\nfrom 1 up to %d', defaultValue);
	caUserInput = inputdlg(userPrompt, userPrompt, 1, {num2str(defaultValue)});
	if isempty(caUserInput),return,end; % Bail out if they clicked Cancel.
	numberOfDoorsToReveal = round(str2num(cell2mat(caUserInput)));
	% Check for a valid integer.
	if isnan(numberOfDoorsToReveal)
		% They didn't enter a number.  
		% They clicked Cancel, or entered a character, symbols, or something else not allowed.
		numberOfDoorsToReveal = defaultValue;
		message = sprintf('I said it had to be an integer.\nI will use %d and continue.', numberOfDoorsToReveal);
		uiwait(warndlg(message));
	end
	% Make sure they didn't enter a number larger than numberOfDoors - 2
	% or all you'd have left is their chosen door.
	numberOfDoorsToReveal = min([numberOfDoors - 2, numberOfDoorsToReveal]);
else
	% With 3 doors, you have to reveal 1.  Nothing else makes sense.
	numberOfDoorsToReveal = 1;	
end

% Ask if the user wants to switch doors after Monty reveals non-winning doors.
message = sprintf('Do you want to switch doors after Monty reveals non-winning doors');
button = questdlg(message, 'Switch?', 'Yes', 'No', 'Yes');
drawnow;	% Refresh screen to get rid of dialog box remnants.
if strcmpi(button, 'Yes')
	contestantSwitches = true;
else
	contestantSwitches = false;
end

numberOfWins = 0;
% For each experiment, pick a random door for the prize to be behind.
prizeDoorList = randi(numberOfDoors, [1, numberOfExperiments]);
% For each experiment, pick a random door that the contestant chooses.
pickedDoorList = randi(numberOfDoors, [1, numberOfExperiments]);

% Now run the Monte Carlo experiments.
for experiment = 1 : numberOfExperiments
	% Get the door that has the prize for this experiment.
	prizeDoor = prizeDoorList(experiment);
	% Get the door that the contestant chose for this experiment.
	pickedDoor = pickedDoorList(experiment);
	% Note: the PickedDoor may be the same or different than prizeDoor.
	if showEachExperiment
	 	fprintf('Experiment #%d.  Prize Door = %d, Picked Door = %d.  ', experiment, prizeDoor, pickedDoor);
	end
	
	% Figure out which door(s) to reveal.
	% First get a list of all the doors.
	otherDoors = 1:numberOfDoors;
	% The other doors which can be revealed will not include
	% the door the contestant picked or the prize door
	otherDoors(pickedDoor) = nan; % Use nan rather than [] so the length won't change.
	otherDoors(prizeDoor) = nan;
	% Now removal all elements flagged as a nan (flagged for removal).
	otherDoors(isnan(otherDoors)) = [];
	% Now we have a list of empty doors that can be revealed.

	% Specify how many to open and reveal the contents.
	% For example we have 12 doors total, but one contains the prize
	% and we need to keep at least 1 still hidden (other than the chosen door).
	% So if we had 12 doors, any number from 1 up to 10 doors can be revealed.

	% Select that number of doors to reveal
	r = randperm(length(otherDoors));
	% Reveal the doors, removing them from the list of "still hidden" doors.
	otherDoors(r(1:numberOfDoorsToReveal)) = [];
	% At this point otherDoors is a list of doors that have not been revealed
	% but not including the prize door or the door that the contestant picked.
	% Now we need to add in the prize door as a door they can switch to,
	% unless they're already on that door.	
	% Now create a list of possible doors that the contestant can switch to if they want.
	doorsThatCanBeSwitchedTo = unique([prizeDoor pickedDoor otherDoors]);
	% Make sure they can't switch to a door that they're already on 
	% because that actually wouldn't even be a switch.
	theirDoorLocation = find(doorsThatCanBeSwitchedTo == pickedDoor);
	doorsThatCanBeSwitchedTo(theirDoorLocation) = []; % Eliminate their door.

	% Now decide if the contestant switches or not.
	if contestantSwitches
		% If they elect to switch, pick a door at random
		% from those than can be switched to
		pickedDoorIndex = randi(length(doorsThatCanBeSwitchedTo), 1);
		pickedDoor = doorsThatCanBeSwitchedTo(pickedDoorIndex);
		if showEachExperiment
			fprintf(' But Switched to Picked Door = %d.', pickedDoor);
		end
	end
	
	% Now see if they won (picked the prize door).
	if pickedDoor == prizeDoor
		numberOfWins = numberOfWins + 1;
		if showEachExperiment
			fprintf('   Win #%d', numberOfWins);
		end
	end
	if showEachExperiment
	 	fprintf('\n');
	end
end	
fprintf('Actual Number of Wins = %d = %.2f%%\n', numberOfWins, 100*numberOfWins/numberOfExperiments);
if contestantSwitches
	fprintf('Predicted win percentage =  %.2f%%\n', ...
		100*(numberOfDoors - 1) / (numberOfDoors * (numberOfDoors - numberOfDoorsToReveal - 1)));
else
	fprintf('Predicted win percentage =  %.2f%%\n', 100*(1)/numberOfDoors);
end