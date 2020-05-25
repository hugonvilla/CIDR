%%%% This script process

%%computes Mouth Indices Mint and Mopen and saves it in a
%%%% big json file for FS search. It also Identifies indices from people
%%%% tracking and creates a big structure
%%%% INPUTS: GetFaceSearch,GetFaceDetect. 
%%%% Output: 'CNPXFSall.json'


clc
close all
clear
warning off

Child='01';

for i=5:14
    Part = num2str(i);
    AD_VideoTool_Aux(Child,Part);
end

function AD_VideoTool_Aux(Child,Part)

%% Filenamescalled by this tool
Mdir = '/Users/PathtoFiles/';
FDjsonfolder = [Mdir,'Child',Child,'/Files/Part',Part,'/JsonFiles/FaceDetection']; %folder with Face Detect json files
FSjsonfolder = [Mdir,'Child',Child,'/Files/Part',Part,'/JsonFiles/FaceSearch/GetFaceSearchFiles']; %folder with Face Search json files
Collecjson = [Mdir,'FaceCollections/CFMFC/CFMFC.json']; %CFMFC face collections
FSjsonwrite = [Mdir,'Child',Child,'/Files/Part',Part,'/JsonFiles/FaceSearch/C',Child,'P',Part,'FS.json'];
%% Hyperparameters
ST = 92; %similarity threshold, [0,100]
%% Parse Json Results
FDdata = dir([FDjsonfolder '/*.json']); %structure containing info on FD folder
valFD=[];
for i=1:numel(FDdata)
    fid = fopen(strcat(FDjsonfolder,'/',FDdata(i).name),'r'); %open json file in position i in IFdata
    raw = fread(fid);str = char(raw');fclose(fid);
    valFDi=jsondecode(str); clear raw str
    valFD = vertcat(valFD,valFDi.Faces);
end
clear valFDi
FSdata = dir([FSjsonfolder '/*.json']); %structure containing info on FD folder
valFS=[];
for i=1:numel(FSdata)
    fid = fopen(strcat(FSjsonfolder,'/',FSdata(i).name),'r'); %open json file in position i in IFdata
    raw = fread(fid);str = char(raw');fclose(fid);
    valFSi=jsondecode(str); clear raw str
    valFS = vertcat(valFS,valFSi.Persons);
end
valWrite.VideoMetadata = valFSi.VideoMetadata;
clear valFSi
% Parse FaceCollection
fid = fopen(Collecjson,'r');
raw = fread(fid);str = char(raw');fclose(fid);
valCF=jsondecode(str);clear raw str
FaceId = {valCF.Faces.FaceId}.';
TrueId = [valCF.Faces.TrueID]; 
LoopId = unique(TrueId); %Id used in the loop add focal child 
Nxv = numel(LoopId); %number of people in the video scene 

%% Video Parameters
fv = valWrite.VideoMetadata.FrameRate;
Tvf = floor(valWrite.VideoMetadata.DurationMillis*fv/1000)-1;
%% Main Loop: Append mouth index to FaceSearch
    kindx = zeros(1,Nxv+1); %to count unidentified

    for k=1:Tvf %for k=1:Tvf % while hasFrame(vr) % I need the "hasframe" here to extract the frames for Mint
        Tstamp= (k)*1000/fv;  %time in ms

        %%% Get Indices
        clear indFS indFD
        indFS = find(abs([valFS.Timestamp]-Tstamp)<500/fv);
        indFD = find(abs([valFD.Timestamp]-Tstamp)<500/fv);

        if isempty(indFS)== 0 %if FaceSearch is not empty
            for i = 1:length(indFS)   
                %Identification
                if isempty(valFS(indFS(i)).FaceMatches) == 0 %only care for identified faces
                    if (valFS(indFS(i)).FaceMatches(1).Similarity >= ST) %if similarity is above threshold
                        Fid = valFS(indFS(i)).FaceMatches(1).Face.FaceId; %face id
                        Findx = find(contains(FaceId,Fid)); %index in TrueId vector
                        Indx = TrueId(Findx); %Person Index corresponding to i.
                        Inl(i) = find(LoopId==Indx); %Id used in the loop, to avoid using the TrueID as index, which will result in big matrices
                        kindx(Inl(i)) = kindx(Inl(i))+1; %detection counter
                        valFS(indFS(i)).TrueId = Indx; %Append TrueID to structure 
                        %Retrieve Bounding Boxes and features
                        BoxSFS = [valFS(indFS(i)).Person.Face.BoundingBox];
                        BoxFS = [BoxSFS.Left BoxSFS.Top BoxSFS.Width BoxSFS.Height];
                        if isempty(indFD) == 0
                            for j = 1:length(indFD)
                                BoxSFD = [valFD(indFD(j)).Face.BoundingBox];
                                BoxFD(j,:) = [BoxSFD.Left BoxSFD.Top BoxSFD.Width BoxSFD.Height];
                            end
                            iM = ismember(BoxFD,BoxFS,'rows'); %Match FD with FS
                            indFM = find(iM); %index in FD that correspond to FS
                            if isfield(valFD(indFD(indFM)).Face,'MouthOpen') == 1 %if there is "FaceDetect" results
                                Mopen = valFD(indFD(indFM)).Face.MouthOpen.Value;
                                MopenConf = valFD(indFD(indFM)).Face.MouthOpen.Confidence;
                                EyesOpen = valFD(indFD(indFM)).Face.EyesOpen.Value;
                                EyesOpenConf = valFD(indFD(indFM)).Face.EyesOpen.Confidence;
                                Age = [valFD(indFD(indFM)).Face.AgeRange.Low;valFD(indFD(indFM)).Face.AgeRange.High];
                                for z = 1:8
                                    if strcmp(valFD(indFD(indFM)).Face.Emotions(z).Type,'CONFUSED')==1
                                        Emotions(1,1) = valFD(indFD(indFM)).Face.Emotions(z).Confidence;
                                    elseif strcmp(valFD(indFD(indFM)).Face.Emotions(z).Type,'ANGRY')==1
                                        Emotions(2,1) = valFD(indFD(indFM)).Face.Emotions(z).Confidence;
                                    elseif strcmp(valFD(indFD(indFM)).Face.Emotions(z).Type,'SAD')==1
                                        Emotions(3,1) = valFD(indFD(indFM)).Face.Emotions(z).Confidence;
                                    elseif strcmp(valFD(indFD(indFM)).Face.Emotions(z).Type,'CALM')==1
                                        Emotions(4,1) = valFD(indFD(indFM)).Face.Emotions(z).Confidence;
                                    elseif strcmp(valFD(indFD(indFM)).Face.Emotions(z).Type,'FEAR')==1
                                        Emotions(5,1) = valFD(indFD(indFM)).Face.Emotions(z).Confidence;
                                    elseif strcmp(valFD(indFD(indFM)).Face.Emotions(z).Type,'DISGUSTED')==1
                                        Emotions(6,1) = valFD(indFD(indFM)).Face.Emotions(z).Confidence; 
                                    elseif strcmp(valFD(indFD(indFM)).Face.Emotions(z).Type,'HAPPY')==1
                                        Emotions(7,1) = valFD(indFD(indFM)).Face.Emotions(z).Confidence;
                                    elseif strcmp(valFD(indFD(indFM)).Face.Emotions(z).Type,'SURPRISED')==1
                                        Emotions(8,1) = valFD(indFD(indFM)).Face.Emotions(z).Confidence;
                                    end      
                                end
                                Age = [valFD(indFD(indFM)).Face.AgeRange.Low;valFD(indFD(indFM)).Face.AgeRange.High];
                                Smile = valFD(indFD(indFM)).Face.Smile.Value;
                                SmileConf = valFD(indFD(indFM)).Face.Smile.Confidence;
                            else
                                Mopen=0;
                                MopenConf=0;
                                EyesOpen=0;
                                EyesOpenConf=0;
                                Emotions = zeros(8,1);
                                Age = zeros(2,1);
                                Smile = 0;
                                SmileConf=0;
                            end
                        else %if no FD
                            Mopen = 0;
                            MopenConf=0;
                            EyesOpen=0;
                            EyesOpenConf=0;
                            Emotions = zeros(8,1); 
                            Age = zeros(2,1);
                            Smile=0;
                            SmileConf=0;
                        end
                        %Assign values to Structure
                        valFS(indFS(i)).Person.Face.Mopen = Mopen;
                        valFS(indFS(i)).Person.Face.MopenConf = MopenConf;
                        valFS(indFS(i)).Person.Face.EyesOpen = EyesOpen;
                        valFS(indFS(i)).Person.Face.EyesOpenConf = EyesOpenConf;
                        valFS(indFS(i)).Person.Face.Emotions = Emotions;
                        valFS(indFS(i)).Person.Face.Age = Age;
                        valFS(indFS(i)).Person.Face.Smile = Smile;
                        valFS(indFS(i)).Person.Face.SmileConf = SmileConf;
                       
                    else %if similarity index is not above threshold
                        kindx(Nxv+1) = kindx(Nxv+1)+1; %detection counter
                        valFS(indFS(i)) = []; %delete row
                        indFS = indFS-1; %account for deleted row
                    end
                else%if GetFaceSearch could not match the face
                    kindx(Nxv+1) = kindx(Nxv+1)+1; %detection counter
                    valFS(indFS(i)) = []; %delete row
                    indFS = indFS-1; %account for deleted row
                end
            end
        end
    end

    %%% Write Json file
    valWrite.Persons = valFS;
    valWrite.LoopId = LoopId;
    jsonStr = jsonencode(valWrite);
    fid = fopen(FSjsonwrite,'w');
    if fid == -1, error('Cannot create JSON file'); end
    fwrite(fid, jsonStr, 'char');
    fclose(fid);

end







