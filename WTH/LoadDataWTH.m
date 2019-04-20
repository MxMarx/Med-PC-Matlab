function output = LoadData(fname)
% open the file for reading
fid = fopen(fname);

% read the text as a 1xn character array
chars = fscanf(fid,'%c');
fclose(fid);

% Convert events from IDs to names, by using a categorical array.
% Optional, but categorical arrays might make everything cleaner
keys = {
    3  , 'Right active FR press'
    4  , 'Left active FR press'
    5  , 'Infusion start'
    6  , 'Infusion end'
    10  , 'Right lever extends'
    11  , 'Left lever extends'
    12  , 'Right lever retracts'
    13  , 'Left lever retracts'
    36  , 'Right press during infusion'
    37  , 'Left press during infusion'
    38  , 'Right lever cue light on'
    39  , 'Left lever cue light on'
    40  , 'Right lever cue light off'
    41  , 'Left lever cue light off'
    42  , 'Houselight on'
    43  , 'Houselight off'
    44  , 'Start of timeout period'
    45  , 'End of timeout period'
    50  , 'Green cue light on'
    51  , 'Green cue light off'
    52  , 'Decrement dose'
    53  , 'Tone on'
    54  , 'Tone off'
    100  , 'End session marker'};
values = [keys{:,1}];
names = keys(:,2);

dates = strfind(chars,'Start Date:');

% For each box
output = [];
for s = dates
    rat = chars(s:end);
    
    % number of events
    eventcount = textscan(rat,'G: %f',1,'HeaderLines',10);
    eventcount = eventcount{1};
    
    %% time, event, dose
    tStart = strfind(rat,'T:')+2;
    times = textscan(rat(tStart:end),'%f: %f %f %f %f %f');
    times = reshape([times{2:6}]',[],1);
    
    eStart = strfind(rat,'E:')+2;
    event = textscan(rat(eStart:end),'%f: %f %f %f %f %f');
    event = reshape([event{2:6}]',[],1);
    event = categorical(event,values,names);
    
    dStart = strfind(rat,'D:')+2;
    dose = textscan(rat(dStart:end),'%f: %f %f %f %f %f');
    dose = reshape([dose{2:6}]',[],1);
    doseIDX = cumsum(event == 'Decrement dose'); %Where the dose decreases
    dose =  dose(doseIDX+1);

    
    id = textscan(rat,[
        'Start Date: %C \r\n',...
        'End Date: %C \r\n',...
        'Subject: %f \r\n',...
        'Experiment: %C \r\n',...
        'Group: %C \r\n',...
        'Box: %C \r\n'],1);
    
    subject = repmat(id{3},length(event),1);
    experiment = repmat(id{4},length(event),1);
    group = repmat(id{5},length(event),1);
    box = repmat(id{6},length(event),1);
    date = repmat(id{1},length(event),1);
    
    session = strsplit(fname,'_');
    session = session{end-1};
    session = session(4:end);
    session = str2num(session);
    session = repmat(session,length(event),1);


    t = table(subject,experiment,group,box,date,times,event,dose,session);%'variableNames',{'subject','experiment','group','box','date','time','event','dose'});
    t = t(1:eventcount,:);
    output = [output; t];
end


