% This script is used to append TrueID to List of Faces in Face Collection
% to be used in AVTool. 
% Replace directories with local paths.
clc
close all
clear

Child='14';

%% Filenames employed by this tool
FCjson = '/Users/PathtoFaceCollection/FaceCollectionName.json'; %obtained using AWSCollecListFaces.py
IFjson = '/Users/PathtoFaceCollection'; %folder containing json files for each image in the face collection
%% Parse Results
%%% Parse ListFaces
fid = fopen(FCjson,'r');
raw = fread(fid);str = char(raw');fclose(fid);
valFC=jsondecode(str); clear raw str
FaceId = {valFC.Faces.FaceId}.';

%% Loop
IFdata = dir([IFjson '/*.json']); %structure containing info on IF folder

for i=1:numel(IFdata)
    fid = fopen(strcat(IFjson,'/',IFdata(i).name),'r'); %open json file in position i in IFdata
    raw = fread(fid);str = char(raw');fclose(fid);
    valFCi=jsondecode(str); clear raw str
    for j = 1:numel(valFCi.FaceRecords)
        Fid = valFCi.FaceRecords(j).Face.FaceId;
        Findx = find(contains(FaceId,Fid)); %matches Face "j" in json file "i" with face in List FaceId
        valFC.Faces(Findx).TrueID = valFCi.FaceRecords(j).TrueID; %append TrueID to structure valFC
    end
    clear valFCi
end

%% Rewrite Json file
jsonStr = jsonencode(valFC);
fid = fopen(FCjson, 'w');
if fid == -1, error('Cannot create JSON file'); end
fwrite(fid, jsonStr, 'char');
fclose(fid);

