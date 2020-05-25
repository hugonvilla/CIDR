%clc
%close all
clear
warning off

%%%%% This function trains the Reciprocal Interaction classifier
%% Individuals
ChVec = "01";
Vchf = 1;
Vcho = 1;

%% Hyperparameters
Kf = 0.25*(29.97);
fv = 29.97/Kf; %default sample frequency (fps)
Tsm = (1000/Kf); %smoothness parameter, in frames. Moving average window. 
Nma = 1; %number of adult faces to include
Nmp = 1; %number of peer faces to include
%% Load Classifiers
PC=load('Data/DL_RMB.mat');
netPI = PC.DL.netPI;
netAI = PC.DL.netAI; 

%% Loop
for i=1:numel(ChVec)
    clear Scb Sab Vb Ab Bb Amb Bmb IGTcb IGTab IGTcbnn IGTabnn
    Child = ChVec(i);
    Nvid = Vcho(i):Vchf(i);
    Tini = 0; %initial time for child
    %% Main Loop
    for j= 1:numel(Nvid)
        FSjson = 'Data/FS.json'; %Face Search Output
        AUjson = 'Data/AU.json';
        GTint = 'Data/IGT.csv';
        
        [Ska,Skc,Vk,Ak,Amk,Tend] = RetrieveFeatures(FSjson,AUjson,fv,Nma,Nmp,Tini);
        Tini = Tini+Tend;
        
        %% Interaction CodingParsing:      
        [IGTak,IGTck] = CodingParser(GTint,size(Vk,1),fv);
        %% Save Data 
        Scb{j} = Skc(~isnan(IGTck),:); Sab{j} = Ska(~isnan(IGTak),:); Vb{j} = Vk(~isnan(IGTak),:); %for LSTM
        Ab{j} = Ak(~isnan(IGTck),:); 
        IGTcbnn{j} = IGTck; IGTabnn{j} = IGTak; %interaction ground truth for peers and adults
        IGTcb{j} = IGTck(~isnan(IGTck)); IGTab{j} = IGTak(~isnan(IGTak)); %interaction ground truth for peers and adults
        
        Amb{j} = Amk; %transcripts
    end 
    Sci{i} = vertcat(Scb{:}); Sai{i} = vertcat(Sab{:});
    Ai{i} = vertcat(Ab{:}); 
    IGTcinn{i} = vertcat(IGTcbnn{:}); IGTainn{i} = vertcat(IGTabnn{:}); %holds true timestamps 
    IGTci{i} = categorical(vertcat(IGTcb{:})'); IGTai{i} = categorical(vertcat(IGTab{:})'); 
    
    Ami{i} = vertcat(Amb{:});
    Vi{i} = vertcat(Vb{:});
    

    %% Predict on each child   
    Sin{i} = [Sai{i} Sci{i}]; 
    Sic{i} = Ai{i};
    
    Sii = Sin{i}; 
    %%%% Infilling
    Sii(Sii==0)=nan;
    for k=1:size(Sii,2) %smoothing
        Sii(:,k) = filloutliers(Sii(:,k),'clip','percentiles',[0 99.5]);
        Sii(:,k) = fillmissing(Sii(:,k),'movmean',Tsm); Sii(isnan(Sii(:,k))==1,k)=0;
    end
    Sii(isnan(Sii))=0; %to fix remaining nans, if there are. 
    
    Vii = Vi{i};
    Vii(Vii==0)=nan;
    for k=1:size(Vii,2) %smoothing
        Vii(:,k) = filloutliers(Vii(:,k),'clip','percentiles',[0 99.5]); %current results are not w clip
        Vii(:,k) = fillmissing(Vii(:,k),'movmean',Tsm); Vii(isnan(Vii(:,k))==1,k)=0;
    end
    Vii(isnan(Vii))=0;  %to fix remaining nans, if there are. 

    Vip{i} = Vii;
    %%%% Normalizing
    Sii = normalize(Sii,'zscore'); %normalize all
    Sinp{i} = Sii;
    Siic = Sic{i}; %audio features
    Sicp{i} = normalize(Siic,'zscore');
    Si{i} = [Sicp{i} Sinp{i}]';
    
    YPredAI = classify(netAI,Si{i});
    YPredPI = classify(netPI,Si{i});
    YPredAI = double(YPredAI); 
    YPredPI = double(YPredPI);
    
    Hai = YPredAI'-1;
    Hpi = YPredPI'-1;
    
    VT = (length(IGTci{i})/(600*fv)); %valid recording duration in X minutes
    DT(i) = VT; %total duration
    
    %%% Reciprocal Interaction measures
    RI = RIMeasures(Hai,Hpi,fv);
    FI(i,:) = [RI.FI]./VT;
    MD(i,:) = [RI.MD];
    ND(i,:) = [RI.ND];
    SD(i,:) = [RI.SD];
    ZD(i,:) = [RI.ZD]./VT;
    
    %%% CDS Measures
    Hain = nan(size(IGTainn{i}));
    Hain(~isnan(IGTainn{i})) = Hai; %to maitain original timestamps. -1 to convert to 0 1 again
    Hpin = nan(size(IGTcinn{i}));
    Hpin(~isnan(IGTcinn{i})) = Hpi;
    Hai=Hain; Hpi=Hpin;
    
    [THi] = DiarizeCDS(Vi{i},Hpi,Hai,Ami{i},fv);
    CM = CDSMeasures(THi);
    NU(i,:) = [CM.NU]./VT;
    NW(i,:) = [CM.NW]./VT;
    WC(i,:) = [CM.WC]./VT;
    Hab{i} = Hai;
    Hpb{i} = Hpi;
    i
end

%%% Aggregate measures
MA.FI = [FI(:,1)];
MA.ND = [ND(:,1)];
MA.SD = [SD(:,1)];
MA.ZD = [ZD(:,1)];
MA.NU = [NU(:,1)];
MA.NW = [NW(:,1)];
MA.WC = [WC(:,1)];
MA.ML = fillmissing(MA.WC./MA.NU,'constant',0);
MA.TR = fillmissing(MA.NW./MA.WC,'constant',0);

MP.FI = [FI(:,2)];
MP.ND = [ND(:,2)];
MP.SD = [SD(:,2)];
MP.ZD = [ZD(:,2)];
MP.NU = [NU(:,2)];
MP.NW = [NW(:,2)];
MP.WC = [WC(:,2)];
MP.ML = fillmissing(MP.WC./MP.NU,'constant',0);
MP.TR = fillmissing(MP.NW./MP.WC,'constant',0);

MF.FI = [FI(:,2)+FI(:,1)];
MF.ND = [mean([ND(:,2),ND(:,1)],2)];
MF.SD = [mean([SD(:,2),SD(:,1)],2)];
MF.ZD = [ZD(:,2)+ZD(:,1)];
MF.NU = [NU(:,3)];
MF.NW = [NW(:,3)];
MF.WC = [WC(:,3)];
MF.ML = fillmissing(MF.WC./MF.NU,'constant',0);
MF.TR = fillmissing(MF.NW./MF.WC,'constant',0);
%% OLP adaptation

AD_PC = load('Data/ADP_MB.mat');
AP = AD_PC.AD.p;
AA = AD_PC.AD.a; %if using MB for adult
AF = AD_PC.AD.f;

MAn = Kpredict(MA,AA);
MPn = Kpredict(MP,AP);
MFn = Kpredict(MF,AF);

figure
i=1;
subplot(2,1,1)
plot(0:1/fv:(numel(Hab{i})-1)/fv,Hab{i})
axis([0 (numel(Hab{i})-1)/fv -0.1 1.1])
title('Predicted Interactions with Adults')
subplot(2,1,2)
plot(0:1/fv:(numel(Hpb{i})-1)/fv,Hpb{i})
axis([0 (numel(Hpb{i})-1)/fv -0.1 1.1])
title('Predicted Interactions with Peers')




