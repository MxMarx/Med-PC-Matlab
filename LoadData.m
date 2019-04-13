function [binned_data, timestamps] = LoadData(fname,get_timestamps)
% open the file for reading
fid = fopen(fname);

% read the text as a 1xn character array
chars = fscanf(fid,'%c');
fclose(fid);

% If the file name contains "NR", the room is "New Room".
room = categorical(contains(fname,'NR','Ignorecase',true),[0 1],{'Old Room','New Room'});

% Find the place in the file where the data from each box starts
dates = strfind(chars,'Start Date:');


timestamps = [];
binned_data = [];

% For each box
for s = dates
    rat = chars(s:end);
    
    
    % Get the binned data
    infusions_bin = get_data_and_reshape(rat,'K');
    total_infusions = sum(infusions_bin);
    
    activelever_bin = get_data_and_reshape(rat,'L');
    total_activelever = sum(activelever_bin);
    
    inactivelever_bin = get_data_and_reshape(rat,'M');
    total_inactivelever = sum(inactivelever_bin);
    
    
    % Get the timestamps
    if get_timestamps
        % For some reason, there might be a different number of binned lever
        % presses and timestamps. To get around this, find the total number
        % of events, and the position of the largest timestamp, and take
        % however many would be smallest. For example, if timestamps were
        % equal to [0,1,2,4,5,6,0,0,0], but the binned data sum to 8, the
        % output would be [0,1,2,3,4,5,6] because the max value was at
        % position 7. Otherwise, the result would be [0,1,2,3,4,5,6,0].
        infusion_time = get_data_and_reshape(rat,'I');
        [~,idx] = max(infusion_time);
        idx = min(idx,total_infusions);
        infusion_time = infusion_time(1:idx);
        
        activelever_time = get_data_and_reshape(rat,'P');
        [~,idx] = max(activelever_time);
        idx = min(idx,total_activelever);
        activelever_time = activelever_time(1:idx);
        
        
        inactivelever_time = get_data_and_reshape(rat,'O');
        [~,idx] = max(inactivelever_time);
        idx = min(idx,total_inactivelever);
        inactivelever_time = inactivelever_time(1:idx);
        
    end
    
    %% Get the metadata
    id = textscan(rat,[
        'Start Date: %q \r\n',...
        'End Date: %C \r\n',...
        'Subject: %f \r\n',...
        'Experiment: %C \r\n',...
        'Group: %C \r\n',...
        'Box: %C \r\n',...
        'Start Time: %q \r\n'],1);
    subject = id{3};
    experiment = id{4};
    group = id{5};
    box = id{6};
    date = datetime([id{1}{1} ' ' id{7}{1}]);
    session = strsplit(fname,'_');
    session = session{end-1};
    session = session(2:end);
    session = str2num(session);
    filename = categorical({fname});
    subject_data = table(subject,experiment,group,box,date,filename,room,session);
    
    event_counts = table(total_infusions,total_activelever,total_inactivelever,'VariableNames',{'Infusions','ActiveLeverPresses','InactiveLeverPresses'});
    binned_data = [binned_data; subject_data, event_counts];
    
    if get_timestamps
        %% Stack the timestamps on top of each other
        time = [infusion_time;activelever_time;inactivelever_time];
        
        % Make a categorical array of the events corresponding to the timestamps
        event = [
            repmat(categorical({'Infusions'}),length(infusion_time),1)
            repmat(categorical({'Active lever presses'}),length(activelever_time),1)
            repmat(categorical({'Inactive lever presses'}),length(inactivelever_time),1)];
        event_data = table(time,event);
        
        % Duplicate subject_data so it is the same length as event_data, and
        % combined the two tables
        subject_data = repmat(subject_data,height(event_data),1);
        timestamps = [timestamps; subject_data, event_data];
    end
    
end


function data = get_data_and_reshape(chars,letter)
% Find the line where the data starts
StartLine = strfind(chars,[char(10) letter ':'])+3;

% Read the data by applying the format
data = textscan(chars(StartLine:end),'%*f: %f %f %f %f %f');

% Turn the data into a matrix and reshape it
data = cell2mat(data);
data = reshape(data',[],1);


