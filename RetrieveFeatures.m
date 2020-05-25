function [Sa,Sc,V,A,Am,Tend] =    RetrieveFeatures(FSjson,AUjson,fv,Nma,Nmp,Tini)
%%%% This script locates, identify, and detects talking faces and it
%%%% matches them with identified speech segments (or voice clusters) from
%%%% all parts
%%%% INPUTS: jsonfiles for FS, Audio, Videoname, and Face Collection
warning off
%% Parse Json Results
%%% Parse FaceSearch
fid = fopen(FSjson,'r');
raw = fread(fid);str = char(raw');fclose(fid);
valFS=jsondecode(str);clear raw str
LoopId = valFS.LoopId; %Id used in the loop  
Nvx = numel(LoopId); %number of people in the video scene
%% Video Parameters
Tvf = floor(valFS.VideoMetadata.DurationMillis*fv/1000)-1;

%% Parse Audio Result
fid = fopen(AUjson,'r');
raw = fread(fid);str = char(raw');fclose(fid);
valAU=jsondecode(str);clear raw str
Am = struct2table(valAU.results.diarized); 
An = [Am{:,1} Am{:,3} Am{:,5} Am{:,6}];
An(:,1) = An(:,1); %remove chapter initial time
An(:,2) = An(:,2);
for k = 1:size(Am,1)
    An(k,5) = mean(Am.Var7{k});
end
Am{:,1}=Am{:,1}+Tini; %to place in total time
Am{:,3}=Am{:,3}+Tini;
    
Tend = valFS.VideoMetadata.DurationMillis/1000; %duration of video in seconds



%% Main Loop
valFS = valFS.Persons; %Patch: discard videometadata to conform with old code 
C = zeros(Tvf,Nvx); %face size index
O = zeros(Tvf,Nvx); %mouth open index
I = zeros(Tvf,Nvx); %eyes open index
Y = 0*ones(Tvf,Nvx); %head yaw activity index . O when using internal normalization, 180 when using raw
H = 0*ones(Tvf,Nvx); %head pitch activity index 
R = 0*ones(Tvf,Nvx); %head roll activity index 
A = zeros(Tvf,6); %Audio features

for k=1:Tvf
    Tstamp= (k)*1000/fv;  %time in ms
    
    %%% Get Indices
    indFS = find(abs([valFS.Timestamp]-Tstamp)<500/fv);
    
    if isempty(indFS)== 0 %if it is not empty
        for i = 1:length(indFS)   
            %Identification
            Inli = find(LoopId == valFS(indFS(i)).TrueId); %Id used in the loop, to avoid using the TrueID as index, which will result in big matrices
            %Get Features
            if isfield(valFS(indFS(i)).Person,'Face')== 1
                Yaw = valFS(indFS(i)).Person.Face.Pose.Yaw;
                Pitch = valFS(indFS(i)).Person.Face.Pose.Pitch;
                Roll =valFS(indFS(i)).Person.Face.Pose.Roll;
                cx = valFS(indFS(i)).Person.Face.BoundingBox.Width;
                cy = valFS(indFS(i)).Person.Face.BoundingBox.Height;
                if isfield(valFS(indFS(i)).Person.Face,'Mopen')
                    MopenConf = valFS(indFS(i)).Person.Face.MopenConf;
                    EyesOpenConf = valFS(indFS(i)).Person.Face.EyesOpenConf;
                else
                    MopenConf=0;
                    EyesOpenConf = 0;
                end
            elseif isfield(valFS(indFS(i)).Person,'BoundingBox')== 1
                Yaw = -180; %yaw = 180 because 0 is good
                Pitch = -180;
                Roll = -180;
                cx=0;
                cy=0;
                MopenConf=0;
                EyesOpenConf=0;
            end
%            %Compute Indices
            Ym = [Y(k,Inli);(Yaw+180)/360];
            [~,iy] = min(abs(Ym-0.5));
            Y(k,Inli) = Ym(iy); %yaw index 
            Hm = [H(k,Inli);(Pitch+180)/360];
            [~,ih] = min(abs(Hm-0.5));
            H(k,Inli) = Hm(ih); %pitch index
            Rm = [R(k,Inli);(Roll+180)/360];
            [~,ir] = min(abs(Rm-0.5));
            R(k,Inli) = Rm(ir); %roll index
            O(k,Inli) = max(O(k,Inli),MopenConf/100); %numerical
            I(k,Inli) = max(I(k,Inli),EyesOpenConf/100);
            C(k,Inli) = max(C(k,Inli),cx*cy); %face size index
        end
    end
%     %% Audio loop
    if A(k,1) == 0 && A(k,3)==0 && A(k,5) == 0 %when using con
        indAu = find(An(:,1) <= Tstamp/1000 & An(:,2) >= Tstamp/1000);
        if isempty(indAu)== 0 %if there is audio activity at Tstamp
            if An(indAu,4)==1 %if adult speaker
                A(k:k+ceil((An(indAu,2)-An(indAu,1))/fv),2) = An(indAu,5); %loudness
                A(k:k+ceil((An(indAu,2)-An(indAu,1))/fv),1) = An(indAu,3); %audio activity, indexed by mean confidence
            elseif An(indAu,4)==2  %if focal child speaker
                 A(k:k+ceil((An(indAu,2)-An(indAu,1))/fv),4) = An(indAu,5); %loudness
                 A(k:k+ceil((An(indAu,2)-An(indAu,1))/fv),3) = An(indAu,3); %audio activity, indexed by mean confidence
            elseif An(indAu,4)==3  %if peer speaker
                 A(k:k+ceil((An(indAu,2)-An(indAu,1))/fv),5) = An(indAu,3); %audio activity, indexed by mean confidence
                A(k:k+ceil((An(indAu,2)-An(indAu,1))/fv),6) = An(indAu,5); %loudness
            end
        end
    end
    

end

%% Postprocessing
%%% Separate adults and peers
Cc = C(:,LoopId<=20); Yc = Y(:,LoopId<=20); Oc = O(:,LoopId<=20);
Hc = H(:,LoopId<=20); Rc = R(:,LoopId<=20); Ic = I(:,LoopId<=20);

Ca = C(:,LoopId>20);Ya = Y(:,LoopId>20); Oa = O(:,LoopId>20);
Ha = H(:,LoopId>20); Ra = R(:,LoopId>20); Ia = I(:,LoopId>20);

%% Sorting
%%%% Talking Face
Ccz = Cc./max(Cc,[],'all'); Caz = Ca./max(Ca,[],'all'); 
Cc(isnan(Cc)) = 0; Ca(isnan(Ca)) = 0;
Vc = Ccz;
Va = Caz;
V=[Vc Va];
[~,Ikc] = sort(Vc,2,'descend'); %order wrt face size first
[~,Ika] = sort(Va,2,'descend');
for k =1:size(Cc,1)
    Cc(k,:) = Cc(k,Ikc(k,:)); Ca(k,:) = Ca(k,Ika(k,:));
    Yc(k,:) = Yc(k,Ikc(k,:)); Ya(k,:) = Ya(k,Ika(k,:));
    Oc(k,:) = Oc(k,Ikc(k,:)); Oa(k,:) = Oa(k,Ika(k,:));
    Hc(k,:) = Hc(k,Ikc(k,:)); Ha(k,:) = Ha(k,Ika(k,:));
    Rc(k,:) = Rc(k,Ikc(k,:)); Ra(k,:) = Ra(k,Ika(k,:));
    Ic(k,:) = Ic(k,Ikc(k,:)); Ia(k,:) = Ia(k,Ika(k,:));
end

%%% Select only Nm faces
Cc = Cc(:,1:Nmp); Yc = Yc(:,1:Nmp); Oc = Oc(:,1:Nmp);
Hc = Hc(:,1:Nmp); Rc = Rc(:,1:Nmp); Ic = Ic(:,1:Nmp);

Ca = Ca(:,1:Nma); Ya = Ya(:,1:Nma); Oa = Oa(:,1:Nma);
Ha = Ha(:,1:Nma); Ra = Ra(:,1:Nma); Ia = Ia(:,1:Nma);


%% Select features
 Sa = [Ca Ya Ha Ra Oa Ia]; %Oa and Ia are categorical data
 Sc = [Cc Yc Hc Rc Oc Ic];


end
