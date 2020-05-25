clear

%%%%%%%%%%%%%%%%%%
%%%% Manual Audio Transcript Labeler
%%%%%%%%%%%%%%%%%%

%% Input Data

i=1; % Child number (1 to 13)
j=1; %from 1 to Vchf(i) (see below)

%% Get Files
ChVec = string(['01';'02' ;'03' ;'04'; '05'; '06'; '08'; '09'; '11'; '14'; '16'; '18'; '19']); %child vectors
Vchf = [14 19 19 19 19 4 5 17 4 16 18 5 19]; %final video chapter to include in training data
if j > Vchf(i)
    disp('Chapter number exceeds available chapters')
    return
end
if i > numel(ChVec)
    disp('Child number exceeds available children')
    return
end

Child=ChVec(i);
Nvid = j;
Mdir = '/Users/PathtoFiles'; 
Vfile = strcat(Mdir,'/Video/C',Child,'P',num2str(Nvid),'V.MP4'); %switch to video
AUjson = strcat(Mdir,'/HTTranscripts/C',Child,'P',num2str(Nvid),'AUN10.json');
AUwrite = strcat(Mdir,'/DiarHTTranscripts/C',Child,'P',num2str(Nvid),'AUN10_SPKID.json');

%% Parse Transcript
fid = fopen(AUjson,'r');
raw = fread(fid);str = char(raw');fclose(fid);
valAU=jsondecode(str);clear raw str
Ams = struct2cell(valAU.results.speaker_labels.segments);
Am = ParseAudioTrans(Ams); %features and labels

%% Manual Labeler
vr = VideoReader(Vfile); %read video
fsv = vr.FrameRate;
[au,fsa] = audioread(Vfile); %read audio

%% Manual labeler
tic
flag=1;
for k =1:size(Am,1)
    t0=Am{k,1};
    tf=Am{k,3};
    AUw =  au(t0*fsa+1:min(tf*fsa,size(au,1)));
    VW = read(vr,[round(t0*fsv)+1,round(tf*fsv)]);
    disp([string({'Total' 'Index' 'Initial Time', 'Final Time'}); size(Am,1)  k,t0,tf]) %display initial time
    disp(['Transcript';Am{k,4}])
    while flag == 1
        h=implay(VW);
        h.Parent.Position=[1200,300,410*1.5,300*1.5];
        play(h.DataSource.Controls);
        sound(AUw,fsa)
        flag=input('Play Again? [1] for yes, [0] for no :');
        close(h)
        clear sound;
    end
    flag = 1;
    Am{k,6} = input('Who speaks? [1] Adult, [2] Focal Child, [3] peer, [4] other :');
end
toc

%% Rewrite Json file
%%% Double check for nonempty
ed=[];
for k =1:size(Am,1)
    if isempty(Am{k,6})==1 || Am{k,6}==0
        ed=[ed;k];
    end
end
ed

if isempty(ed)==1
    valAU.results.diarized=Am;
    jsonStr = jsonencode(valAU);
    fid = fopen(AUwrite,'w');
    if fid == -1, error('Cannot create JSON file'); end
    fwrite(fid, jsonStr, 'char');
    fclose(fid);
else
    disp('Error: Empty cells')
end




