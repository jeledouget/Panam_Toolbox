function outputStruct = panam_timeFrequencyProcess( inputStructs, inputEvents, param )
%PANAM_TIMEFREQUENCYPROCESS Function to compute corrections and averages on
%Panam TimeFrequency structures


%% load inputs
% check if the input structures are file adresses or actual matlab structures
% in case of file adresses, load the structures


%% default parameters
% define the default parameters


%% check/affect parameters


%% average contacts
% define the contacts selected for each input structure
% then average over the contacts


%% trials filtering
% select trials which correpond to the specified filter


%% subject averaging
% in case of multi-subjcet inputs, average over subjects if option is selected


%% baseline correction
% apply baseline correction on the trials/subjects :
% decibel - zscore - ratio of change from baseline - (average t-maps ?)


%% events handling
% compute events averages


%% output affectation


%% visualization


end

