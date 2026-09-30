% Data pre-processing for monetary policy shock IRFs
% Alisdair McKay
% Jan 4, 2023
%
clear;
clc;
close all;

%% Monthly FRED data

DT = readtable('Data/Macro_Book_Data.xls','Sheet','Monthly');
first = datevec(DT.observation_date(1));
last = datevec(DT.observation_date(end));

% check that monthly data starts at the beginning of a quarter
assert( any(first(2) == [1 4 7 10]) );
% and ends at the end of a quarter
assert( any(last(2) == [3 6 9 12]));

% aggregate monthly to quarterly using quarterly averages
TQ = size(DT.observation_date,1)/3;  % length of quarterly sample
MQ = first(1)+(first(2)-1)/3/4  + 0.25 * (0:TQ-1)'; % quarter time index
ffr = kron(  eye(TQ) , [1 1 1]/3 )  * DT.FEDFUNDS_20230103;

MT = table(MQ(1:end-1),ffr(1:end-1)); % drop the last quarter to align with quarterly end date
MT.Properties.VariableNames = {'quarter','ffr'};

%% Quarterly FRED data
DT = readtable('Data/Macro_Book_Data.xls','Sheet','Quarterly');

% rename variables
DT.Properties.VariableNames = {'observation_date', 'rgdp', 'pcepriceindex', 'lpcom'};

% create quarter index
first = datevec(DT.observation_date(1));
last = datevec(DT.observation_date(end));
T = size(DT.observation_date,1);
DT.quarter = first(1)+(first(2)-1)/3/4  + 0.25 * (0:T-1)';


% Merge the quarterly and monthly data
DT = join(MT,DT);

%% Quarterly RR shocks
RRT = readtable('Data/romershocks_quarterly.xlsx');

% create quarter index
first = datevec(RRT.date(1));
T = size(RRT.date,1);
RRT.quarter = first(1) + (first(2)-1)/3/4 + 0.25 * (0:T-1)';

% drop variables we don't use
RRT = removevars(RRT,{'date','resid','resid_romer'});

% rename variables
RRT.Properties.VariableNames = {'rrshock', 'quarter'};

% Merge with the rest of the data
DT = outerjoin(DT,RRT);
DT = removevars(DT,{'quarter_RRT'});
qname = DT.Properties.VariableNames(1);
assert(strcmp(qname{:} , 'quarter_DT'))
DT.Properties.VariableNames(1) = {'quarter'};

%% Define new variables;

DT.lrgdp = 100*log(DT.rgdp);
DT.infl = 400*[0;diff(log(DT.pcepriceindex))];


%% Save 
save('Data/processeddata.mat','DT');


