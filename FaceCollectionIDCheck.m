% Script to manually relate each Amazon Face Collection ID with the
% project's unique identifiers. Also employed to delete detected IDs that
% will not be considered in the Face Collection (see comments below).
% Replace "PathtoDir' and 'PathtoFaceCollec' with appropriate local paths

clc
close all
clear

%% 
Child='01';
Part=8;
Nimg=18;
ext = '.png';
%% Filenames employed by this tool
Mdir = '/Users/PathtoDir';  %path to dir
Imgname = strcat(Mdir,'/PathtoFaceCollec/C',Child,'P',num2str(Part),'FC',num2str(Nimg),ext); %path to image
Truejson = strcat(Mdir,'/PathtoFaceCollec/C',Child,'P',num2str(Part),'FC',num2str(Nimg),'.json'); %write label json with this name 
FCjson = strcat(Mdir,'/PathtoFaceCollec/C',Child,'P',num2str(Part),'FC',num2str(Nimg),ext,'.json'); %path to Face Collection
%FCjson = Truejson; %uncomment when double-checking identification
%% Parse Json Result and open 
fid = fopen(FCjson,'r');
raw = fread(fid);str = char(raw');fclose(fid);
val=jsondecode(str); clear raw str

frame = imread(Imgname);
px = size(frame,2); %total width. Recall that in matlab matrices (images), the x coordinates corresponds to columns, and y to rows
py = size(frame,1); %total height

nFace = size([val.FaceRecords],1); %number of faces indexed in json
figure
for i = 1:nFace
    %   Face Bounding Box
    BoxStr = [val.FaceRecords(i).FaceDetail.BoundingBox];
    BoxDb = [BoxStr.Left BoxStr.Top BoxStr.Width BoxStr.Height];
    Bbox(i,:) = [px py px py].*BoxDb; %Face's bounding box. No need to index it with Indx(i). Needs to be positive for printing
    %Mouth BoundingBox
    FacX = px*[val.FaceRecords(i).FaceDetail.Landmarks.X];
    FacY = py*[val.FaceRecords(i).FaceDetail.Landmarks.Y];
    Fac = [FacX' FacY']; %Facial landmarks coordinates
    Mbox(i,:) = [Fac(3,1) Fac(22,2) abs(Fac(4,1)-Fac(3,1)) abs(Fac(23,2)-Fac(22,2))]; %Mouth coordinates
    Yaw(i) = val.FaceRecords(i).FaceDetail.Pose.Yaw;
    Mopen(i) = val.FaceRecords(i).FaceDetail.MouthOpen.Value;
    FaceID(i,1) = string(val.FaceRecords(i).Face.FaceId);
    Brightness(i) = val.FaceRecords(i).FaceDetail.Quality.Brightness;
    Sharpness(i) = val.FaceRecords(i).FaceDetail.Quality.Sharpness;
end
label_str = cell(nFace,1);
for ii=1:nFace
    if isfield(val.FaceRecords,'TrueID')==1
        label_str{ii} = ['Person ' num2str(val.FaceRecords(ii).TrueID) ' Bright ' num2str(Brightness(ii)) ' Sharp ' num2str(Sharpness(ii))];
    else
        label_str{ii} = ['Person ' num2str(ii) ' Bright ' num2str(Brightness(ii)) ' Sharp ' num2str(Sharpness(ii))];
    end
end

RGB = insertShape(frame,'rectangle',Mbox);
RGB = insertObjectAnnotation(RGB,'rectangle',Bbox,label_str,...
    'TextBoxOpacity',0.9,'FontSize',18);
imshow(RGB);
FaceID

%% Delete low quality Faces, Label Faces with True ID and write json file
%%%% Uncomment after checking Figure. Delete old json file with ".jpg" in
%%%% name

%%%%%%%Delete face in AWS Face Collection first with AWSCollecDeleteFaces.py
%%%%%%%and FaceID Labels in FaceID variable in this script
% % % 
% % % % % % % 
%      val.FaceRecords(2:end)=[]; %this deletes low quality faces
% % % % % 
% % % % % %%%%%% Identify faces
% val.FaceRecords(1).TrueID =7;
% %val.FaceRecords(2).TrueID =8;
% %val.FaceRecords(3).TrueID =3;
% %val.FaceRecords(4).TrueID =15;
% 
% %%%%% Write json
% jsonStr = jsonencode(val);
% fid = fopen(Truejson, 'w');
% if fid == -1, error('Cannot create JSON file'); end
% fwrite(fid, jsonStr, 'char');
% fclose(fid);
