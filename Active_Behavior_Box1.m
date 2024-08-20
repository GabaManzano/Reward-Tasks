%% Pathway and saving (Input Info)
clear all
rig.datapath = 'D:\Documents\MATLAB\Behavior Reward Learning\Dreadds Gad2 and VGlut1\Active Behavior'; %What folder you will save in
Mouse.Name=input('Mouse name ', 's'); % The name of the mouse
%Mouse.TestingPhase=input('Developmental phase the mouse is being tested in ', 's');
Mouse.Trial=input('Trial number ', 's'); %For saving the file
Mouse.Sex=input('Sex (M or F) ', 's'); %For saving the file
Mouse.Condition=input('Condition (C or E) ','s'); %For saving the file
RewardTone = input('Rewarded (CS+) tone frequency (9000 or 1000)','s');% Rewarded Tone Frequency either 9000 or 1000

%% Initiating arduino
b = arduino('com6','mega2560');% Arduino you are communicating to;

% Tone Designation (Used for counterbalacing mice)
if RewardTone == strcat('9000') %checks if you wrote 9000 for reward tone frequency
    RewardToneFrequency=9000; %Assigns 9000 as the reward frequency
    NoRewardToneFrequency=1000; %Assigns 1000 as the no-reward frequency
elseif RewardTone == strcat('1000')  %checks if you wrote 1000 for reward tone frequency
    RewardToneFrequency=1000;%Assigns 1000 as the reward frequency
    NoRewardToneFrequency=9000;%Assigns 9000 as the no-reward frequency
end
% Variables
rng('shuffle') %Used in Matlab for randomization of trials
LT=.05; %The open time for the solenoid. Determines the size of the reward. 
ToneDuration=5;% Duration of tones in seconds
RewardDuration=5; %Reward lick opportunity in seconds
TotalTrials=100; % Total number of trials (Must be an Even Number!)
ITIMin=15;%Shortest duration of ITI s (should be set to 15)
ITIMax=30;%Longest duration of ITI s (should be set to 30)

% Constants
ToneChoosingMatrix=[0,1]; %Randomly chooses which tone to play
NoReward=0; %No Reward tone
Reward=1; % Reward Tone
CurrentTrial=1; % initializes the
Habituation=ITIMin; %Duration of Habituation Period
Trial.Type=zeros(TotalTrials);%allocates 0 array
positions=[1:(TotalTrials/2)];%creates half length 1 array
Trial.Type(positions)=1;%creates half 1, half 0 array
Trial.Type=Trial.Type(randperm(length(Trial.Type)));%Randomizes 1s and 0s. 
ITI=zeros(TotalTrials);%allocates 0 array 
ITI=rot90(randi([ITIMin,ITIMax],TotalTrials,1));%creates row (rot90) with randomly generated (randi) ITI values

% Initiate Arduino components
TonePin='D52'; % The arduino pin that is hooked up to the sound
LickingDataPin='D53'; % The arduino pin that is hooked up to the touch sensor

% Initiate Matrixes for Data collection
Trial.Time = zeros(1,TotalTrials);
Licking.ITI.Licks = zeros(TotalTrials,100000);
Licking.NoReward.Licks = zeros(TotalTrials,1000);
Licking.Reward.Licks = zeros(TotalTrials,1000);
Licking.PostTone.Licks = zeros(TotalTrials,1000);
Trial.RewardGiven = zeros(1,TotalTrials);

%creates counters
ToneCounter = 0;
ITICounter = 0;
RewardCounter = 0;
HabCounter=0;
RewardTrial=0;


%% Test mouse is not touching the port
readDigitalPin(b,LickingDataPin) % Checks mouse is not one with the spout. Sometimes people put mouse too close to the spout. 
pause(1)
readDigitalPin(b,LickingDataPin)
pause(1)
readDigitalPin(b,LickingDataPin)
pause(1)
readDigitalPin(b,LickingDataPin)

%%

StartTime = clock;%Start of Trial Time
disp('Habituation')
while etime(clock, StartTime) < Habituation %determines how long the loop will run for
HabCounter = HabCounter+1; %lets you move across the row to input values into the array
Licking.Habituation.Licks(CurrentTrial,HabCounter) = readDigitalPin(b,LickingDataPin);% places lick measures into the matrix
Licking.Habituation.Time(CurrentTrial,HabCounter) = etime(clock,StartTime); %places time stamps for each lick
end

for CurrentTrial=1:(TotalTrials)
Index=Trial.Type(CurrentTrial); %chooses a tone from a previously semi-randmonly generated array
ToneCounter = 0; % Must be reinitiated every loop to place values in a matrix
ITICounter = 0; % Must be reinitiated every loop to place values in a matrix
RewardCounter = 0; % Must be reinitiated every loop to place values in a matrix
disp(num2str(CurrentTrial)) % Displays the word Habituation during the habituation period
LickCounter=0;     

   
    if Index==1 %Rewarded tone loop. If the index value of array Trial.Type is 1 then the reward tone will play and lick data will be acquired in reward matrices
    ToneStartTime = clock; % Used to indicate the total duration of lick sampling. 
    playTone(b,TonePin,RewardToneFrequency,ToneDuration); %reward tone
    Trial.Time(CurrentTrial) = etime(clock,StartTime); % Creates array with time tone played
    RewardTrial=RewardTrial+1;
        while etime(clock, ToneStartTime) < ToneDuration %creates "Reward Period" Tone is off and the mouse can lick for the sucrose.
        ToneCounter = ToneCounter+1; % used to move inputs across the array
        Licking.Reward.Licks(CurrentTrial,ToneCounter) = readDigitalPin(b,LickingDataPin); %Collects lick data into the matrix
        Licking.Reward.Time(CurrentTrial,ToneCounter) = etime(clock,ToneStartTime); % Collects timestamps for licking data
            if readDigitalPin(b,LickingDataPin)==1
            LickCounter=LickCounter+1;
            end
        end
 
                if LickCounter >= 1
                writeDigitalPin(b,'D8',1); %Delivers reward
                pause(LT); % Duration of reward
                writeDigitalPin(b,'D8',0); %Stops reward delivery
                Trial.RewardGiven(CurrentTrial)=1;  %populates a matrix with 1s is they obtained the trial
                disp('Got it!') %Prints "Got it!" on the screen so you know in real time if your mice is doing okay.  
                end
    
        RewardStartTime = clock; % Used to run the licks during reward presentation data
        while etime(clock, RewardStartTime) < RewardDuration % Collects licking information during the duration of the reward presentation.
        RewardCounter = RewardCounter+1; 
        Licking.PostTone.Licks(CurrentTrial,RewardCounter) = readDigitalPin(b,LickingDataPin);
        Licking.PostTone.Time(CurrentTrial,RewardCounter) = etime(clock,ToneStartTime);
        end 
    end
  
    if Index==0 %Not rewarded tone loop. If the index value of array Trial.Type is 0 then the no-reward tone will play and lick data will be acquired in the NoReward matrices
    playTone(b,TonePin,NoRewardToneFrequency,ToneDuration)%No reward tone
    Trial.Time(CurrentTrial) = etime(clock,StartTime);
    ToneStartTime = clock;
        while etime(clock, ToneStartTime) < ToneDuration
        ToneCounter = ToneCounter+1; 
        Licking.NoReward.Licks(CurrentTrial,ToneCounter) = readDigitalPin(b,LickingDataPin);
        Licking.NoReward.Time(CurrentTrial,ToneCounter) = etime(clock,ToneStartTime);
        end

            
        NoRewardStartTime = clock;
        while etime(clock, NoRewardStartTime) < RewardDuration
        RewardCounter = RewardCounter+1; 
        Licking.PostTone.Licks(CurrentTrial,RewardCounter) = readDigitalPin(b,LickingDataPin);
        Licking.PostTone.Time(CurrentTrial,RewardCounter) = etime(clock,ToneStartTime);
        end
    end
    
    ITICurrent=ITI(CurrentTrial);%Chooses ITI that corresponds to the current trial number
    ITIStartTime = clock;%takes the time to compare against the ITI time for counter
   
    while etime(clock, ITIStartTime) < ITICurrent %determines how long the loop will run for
    ITICounter = ITICounter+1; %lets you move across the row to input values into the array
    Licking.ITI.Licks(CurrentTrial,ITICounter) = readDigitalPin(b,LickingDataPin);% places lick measures into the matrix
    Licking.ITI.Time(CurrentTrial,ITICounter) = etime(clock,ITIStartTime); %places time stamps for each lick
    end     
end

disp('Box 1 Finished')

save(strcat(rig.datapath, filesep, Mouse.Name,'-',Mouse.Sex,'-', Mouse.Condition, '-',Mouse.Trial, '-', date, datestr(now, '_HH_MM'), '.mat'), 'Mouse', 'RewardToneFrequency','Licking','rig','Trial','TotalTrials','ToneDuration','ITI');

