%%% This is an auxiliary script to manually check the identification
%%% capabilities of AWSGetFaceSearch.
clc
close all
clear
warning off

Child='01';
Part='12';
Vidn = ['C',Child,'P',Part,'VI.MP4']; %Video_name

%% Filenames employed by this tool
Mdir = '/Users/Pathtofiles/';
FSjsonfolder = strcat(Mdir,'Child',Child,'/Files/Part',Part,'/JsonFiles/FaceSearch/GetFaceSearchFiles');
FDjsonfolder = strcat(Mdir,'Child',Child,'/Files/Part',Part,'/JsonFiles/FaceDetection');
Collecjson = [Mdir,'FaceCollections/CFMFC/CFMFC.json']; %CFMFC face collections
Vidname = [Mdir,'Child',Child,'/Files/Part',Part,'/Video/',Vidn];
Tframe =612478; %Timestamp in ms 
%% Hyperparameter
KM = 0.5; %mouth threshold,[0,1]
ST = 0; %similarity threshold, [0,100]

%% Parse Json Results
FDdata = dir([FDjsonfolder '/*.json']); %structure containing info on FD folder
valFD=[];
for i=1:numel(FDdata)
    fid = fopen(strcat(FDjsonfolder,'/',FDdata(i).name),'r'); %open json file in position i in IFdata
    raw = fread(fid);str = char(raw');fclose(fid);
    valFDi=jsondecode(str); clear raw str
    valFD = vertcat(valFD,valFDi.Faces);
    clear valFCi
end
FSdata = dir([FSjsonfolder '/*.json']); %structure containing info on FD folder
valFS=[];
for i=1:numel(FSdata)
    fid = fopen(strcat(FSjsonfolder,'/',FSdata(i).name),'r'); %open json file in position i in IFdata
    raw = fread(fid);str = char(raw');fclose(fid);
    valFSi=jsondecode(str); clear raw str
    valFS = vertcat(valFS,valFSi.Persons);
    clear valFSi
end

% Parse FaceCollection
fid = fopen(Collecjson,'r');
raw = fread(fid);str = char(raw');fclose(fid);
valCF=jsondecode(str);clear raw str
FaceId = {valCF.Faces.FaceId}.';
TrueId = [valCF.Faces.TrueID]; 
LoopId = unique(TrueId);

%% VideoParameters
vr = VideoReader(Vidname);
fv = vr.FrameRate; %framerate in fps (Hz)
px = vr.Width;
py = vr.Height;

%% Frame parameters
Tstamp = Tframe; %timestamp in ms
vr.CurrentTime = Tstamp/1000; %timestamp in seconds
indFS = find(abs([valFS.Timestamp]-Tstamp)<500/fv);
indFD = find(abs([valFD.Timestamp]-Tstamp)<500/fv);
%% Main Loop
frame = readFrame(vr); %read current frame
label_str = cell(numel(indFS),1);
figure
for i = 1:numel(indFS)
    % Identification
    if isempty(valFS(indFS(i)).FaceMatches) == 0
       if (valFS(indFS(i)).FaceMatches(1).Similarity >= ST)
            Fid = valFS(indFS(i)).FaceMatches(1).Face.FaceId; %face id
            Findx = find(contains(FaceId,Fid)); %index in TrueId vector
            Indx(i) = TrueId(Findx); %Person Index corresponding to i.
            Sim(i) = valFS(indFS(i)).FaceMatches(1).Similarity;
       else
            Indx(i) = nan;
            Sim(i) = nan;
       end
    else
        Indx(i) = nan; %unidentified face
        Sim(i) = nan;
    end
    %Retrieve Bounding Boxes and features
    BoxSFS = [valFS(indFS(i)).Person.Face.BoundingBox];
    BoxFS = [BoxSFS.Left BoxSFS.Top BoxSFS.Width BoxSFS.Height];
    for j = 1:length(indFD)
        BoxSFD = [valFD(indFD(j)).Face.BoundingBox];
        BoxFD(j,:) = [BoxSFD.Left BoxSFD.Top BoxSFD.Width BoxSFD.Height];
    end
    iM = ismember(BoxFD,BoxFS,'rows'); %Match FD with FS
    indFM = find(iM);
    Bbox(i,:) = [px py px py].*BoxFD(indFM,:);
    Mopen = valFD(indFD(indFM)).Face.MouthOpen.Value; %mouth open boolean variable
    Yaw = valFD(indFD(indFM)).Face.Pose.Yaw;
    cx = valFD(indFD(indFM)).Face.BoundingBox.Width;
    cy = valFD(indFD(indFM)).Face.BoundingBox.Height;
    %Mouth Computations
    FacX = px*[valFD(indFD(indFM)).Face.Landmarks.X];
    FacY = py*[valFD(indFD(indFM)).Face.Landmarks.Y];
    Fac = [FacX' FacY']; %Facial landmarks coordinates
    Mbox(i,:) = [Fac(3,1) Fac(22,2) abs(Fac(4,1)-Fac(3,1)) abs(Fac(23,2)-Fac(22,2))]; %Mouth coordinates
    Imouth = frame(max(Mbox(i,2),1):min(Mbox(i,2)+Mbox(i,4),py),max(Mbox(i,1),1):min(Mbox(i,1)+Mbox(i,3),px),:);
    Mopen(i) = valFD(indFD(indFM)).Face.MouthOpen.Value;
    Mint(i) = mean(rgb2gray(Imouth),'all');
    
    label_str{i} = ['Person ' num2str(Indx(i)) ' Sim ' num2str(Sim(i))];
end
RGB = insertObjectAnnotation(frame,'rectangle',Bbox,label_str,...
    'TextBoxOpacity',0.9,'FontSize',18);
RGB = insertShape(RGB,'rectangle',Mbox);
imshow(RGB);






