function output = LoadData(fname)
% open the file for reading
fid = fopen(fname);

% read the text as a 1xn character array
chars = fscanf(fid,'%c');
fclose(fid);

roomT = categorical(contains(fname,'NR','Ignorecase',true),[0 1],{'Old Room','New Room'});


dates = strfind(chars,'Start Date:');




% For each box
output = [];
for s = dates
    rat = chars(s:end);
    
%     SessionLengthStartLine = strfind(rat,[char(10) 'P:'])+3;
%     sessionlength = textscan(rat(SessionLengthStartLine:end),'%f');
%     sessionlength = sessionlength{1} / 100;

InfusionStartLine = strfind(rat,[char(10) 'I:'])+3;
infusions = textscan(rat(InfusionStartLine:end),'%*f: %f %f %f %f %f','collectoutput',true);
infusions = reshape(infusions{1}',[],1);
infusions = infusions(infusions ~= 0);

ActiveLine = strfind(rat,[char(10) 'P:'])+3;
activelever = textscan(rat(ActiveLine:end),'%*f: %f %f %f %f %f','collectoutput',true);
activelever = reshape(activelever{1}',[],1);
activelever = activelever(activelever ~= 0);


InactiveLine = strfind(rat,[char(10) 'O:'])+3;
inactivelever = textscan(rat(InactiveLine:end),'%*f: %f %f %f %f %f','collectoutput',true);
inactivelever = reshape(inactivelever{1}',[],1);
inactivelever = inactivelever(inactivelever ~= 0);

    


id = textscan(rat,[
    'Start Date: %q \r\n',...
    'End Date: %C \r\n',...
    'Subject: %f \r\n',...
    'Experiment: %C \r\n',...
    'Group: %C \r\n',...
    'Box: %C \r\n',...
    'Start Time: %q \r\n'],1);

    tHeight = length(infusions) + length(activelever) + length(inactivelever);
    
    
    time = [infusions;activelever;inactivelever] ;
    
    event = [
        repmat(categorical({'Infusions'}),length(infusions),1)
        repmat(categorical({'Active lever presses'}),length(activelever),1)
        repmat(categorical({'Inactive lever presses'}),length(inactivelever),1)];
    
    subject = repmat(id{3},tHeight,1);
    experiment = repmat(id{4},tHeight,1);
    group = repmat(id{5},tHeight,1);
    box = repmat(id{6},tHeight,1);
    date = repmat(datetime([id{1}{1} ' ' id{7}{1}]) ,tHeight,1);
    filename = repmat(categorical({fname}),tHeight,1);
    room = repmat(roomT,tHeight,1);

    
    t = table(subject,experiment,room,group,box,date,filename,time,event);
    
    output = [output; t];
end
output = output(~isnan(output.time),:);

