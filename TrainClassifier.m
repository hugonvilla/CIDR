%clc
%close all
clear
warning off

%%%%% This function trains the Reciprocal Interaction classifier
%% All kids
ChVec = string(['01';'02' ;'03' ;'04'; '05'; '06'; '08'; '09'; '11'; '14'; '16'; '18'; '19']); %child vectors, it will be huge.
Vchf = [3 5 5 5 4 4 5 5 4 5 5 5 5]; %final video chapter to include in training data
Vcho = 1*ones(size(ChVec)); %initial video chapter to include in training data
%% Hyperparameters
Kf = 0.25*(29.97); 
fv = 29.97/Kf; %default sample frequency (fps)
Tsm = 1*(1000/Kf); %smoothness parameter, in frames. Moving average window. 
Nma = 1; %number of faces to include in adult classifier
Nmp = 1; %number of faces to include in peer classifier
%% Loop
Mdir = '/Users/PathtoFiles';
for i= 1:numel(ChVec)
    clear Scb Sab Vb Ab Bb Amb Bmb IGTcb IGTab Rtb IGTcbnn IGTabnn
    Child = ChVec(i);
    Nvid = Vcho(i):Vchf(i);
    Tini = 0; %initial time for child
    %% Main Loop
    for j= 1:numel(Nvid)
        FSjson = strcat(Mdir,'/VisualFeatures/C',Child,'P',num2str(Nvid(j)),'FS.json'); %FS only
        AUjson = strcat(Mdir,'/AudioFeatures/C',Child,'P',num2str(Nvid(j)),'SPFEAT.json');
        GTint = strcat(Mdir,'/RICoding/C',Child,'P',num2str(Nvid(j)),'IGT.csv');
        GTtrans = strcat(Mdir,'/GTTranscripts/C',Child,'P',num2str(Nvid(j)),'TGT.txt'); %transcription GT

        [Ska,Skc,Vk,Ak,Amk,Tend] = RetrieveFeatures(FSjson,AUjson,fv,Nma,Nmp,Tini);
        Tini = Tini+Tend;

        %% Interaction CodingParsing:      
        [IGTak,IGTck] = CodingParser(GTint,size(Vk,1),fv);
        [TRk] = GTTranscriptParser(GTtrans); %Transcript Parser for GT
        %% Save Data 
        Scb{j} = Skc(~isnan(IGTck),:); Sab{j} = Ska(~isnan(IGTak),:); Vb{j} = Vk(~isnan(IGTak),:); %for LSTM
        Ab{j} = Ak(~isnan(IGTck),:); %audio activity 
        IGTcbnn{j} = IGTck; IGTabnn{j} = IGTak; %interaction ground truth for peers and adults
        IGTcb{j} = IGTck(~isnan(IGTck)); IGTab{j} = IGTak(~isnan(IGTak)); %interaction ground truth for peers and adults

        Amb{j} = Amk; %transcripts
        Rtb{j} = TRk; %Reference transcript measures
    end
    %% Preprocessing accross chapters (on each child)
    Sci{i} = vertcat(Scb{:}); Sai{i} = vertcat(Sab{:}); 
    Ai{i} = vertcat(Ab{:});
    IGTcinn{i} = vertcat(IGTcbnn{:}); IGTainn{i} = vertcat(IGTabnn{:}); %holds true timestamps 
    IGTci{i} = categorical(vertcat(IGTcb{:})'); IGTai{i} = categorical(vertcat(IGTab{:})'); 
    
    Ami{i} = vertcat(Amb{:}); 
    Vi{i} = vertcat(Vb{:});
    Rtc{i} = vertcat(Rtb{:});
    Sin{i} = [Sai{i} Sci{i}];
    Sic{i} = Ai{i};
end
 
 %% Data Processing
for i=1:numel(ChVec)
    Sii = Sin{i}; %video features
    %Sii = [Sin{i}(:,1) Sin{i}(:,size(Sai{1},2)+1)]; %face only
    
    %%%%% Infilling
    Sii(Sii==0)=nan;
    for k=1:size(Sii,2) %smoothing
        Sii(:,k) = filloutliers(Sii(:,k),'clip','percentiles',[0 99.5]); %99.5
        Sii(:,k) = fillmissing(Sii(:,k),'movmean',Tsm); Sii(isnan(Sii(:,k))==1,k)=0;
    end
    Sii(isnan(Sii))=0; %to fix remaining nans, if there are. Might be a patch  
    Sii = normalize(Sii,'zscore'); %normalize all
    Sinp{i} = Sii;
    
    Siic = Sic{i}; %audio features
    Siic = normalize(Siic,'zscore');
    Sicp{i} = Siic;
    Si{i} = [Sicp{i} Sinp{i}]';
end

%% Leave-one-person-out cross correlation for Model Selection
rng(10)
clear EA EP CMA CMP NU MLU NW FI MD ND SD OP ZD Hab Hpb 
Nf = size(ChVec,1);
tic
for j = 1:size(ChVec,1) %1:Nf
   %% Data preparation
    %%% Testing Data Set
    InTest=1:size(IGTci,2);
    InTest(j)=[];
    XTrain = Si(InTest)';
    XTest = Si(j);
    YTrainAI = IGTai(InTest)';
    YTestAI=IGTai{j};
    YTrainPI = IGTci(InTest)';
    YTestPI=IGTci{j};
    
    %% Define LSTM
    numFeatures = size(Si{1},1);
    numHiddenUnits = 60;
    numClasses = 2;

    layers = [ ...
        sequenceInputLayer(numFeatures)
        bilstmLayer(numHiddenUnits,'OutputMode','sequence')
        dropoutLayer(0.2)
        bilstmLayer(numHiddenUnits,'OutputMode','sequence')
        fullyConnectedLayer(numClasses)
        softmaxLayer
        classificationLayer]; %dropoutLayer(0.2)

    maxEpochs     = 30;
   
    miniBatchSize = 64;
    options = trainingOptions("adam", ...
        "MaxEpochs",maxEpochs, ...
        "MiniBatchSize",miniBatchSize, ...
        "Shuffle","every-epoch",...
        "Verbose",0, ....
        "LearnRateSchedule","piecewise",...
        "LearnRateDropFactor",0.1, ...
        "LearnRateDropPeriod",10); %,'Plots','training-progress');

    %% Train LSTM
    netAI = trainNetwork(XTrain,YTrainAI,layers,options);
    netPI = trainNetwork(XTrain,YTrainPI,layers,options);

    %% Prediction
    YPredAI = classify(netAI,XTest); %YTestAI+1 when only focusing on peers to cut time
    YPredPI = classify(netPI,XTest); %classify(netPI,XTest); %YTestPI
    YPredAI = double(YPredAI{1}); %to include back the rows taken to avoid nans in LSTM 
    YPredPI = double(YPredPI{1}); %to include back the rows taken to avoid nans in LSTM 
    Haj = YPredAI'-1;
    Hpj = YPredPI'-1;

    VT = (length(IGTci{j})/(600*fv)); %valid recording duration in multiples of 10 minutes
    
    %%% Errors
    IGTajth = double(IGTai{j}')-1; IGTpjth = double(IGTci{j}')-1; %clean
    EA(j) = nansum(abs(IGTajth-Haj)); %error adult interactions, exclude nonobservations (IGTajt = nan)
    EP(j) = nansum(abs(IGTpjth-Hpj)); %error peer interactions 
    CMA(:,:,j) = confusionmat(IGTajth,Haj); %confusion matrix
    CMP(:,:,j) = confusionmat(IGTpjth,Hpj);
    
    %%% RI Measures
    RI = RIMeasures(Haj,Hpj,fv);
    RIG = RIMeasures(IGTajth,IGTpjth,fv);
    FI(j,:) = [RIG.FI RI.FI]./VT;
    MD(j,:) = [RIG.MD RI.MD];
    ND(j,:) = [RIG.ND RI.ND];
    SD(j,:) = [RIG.SD RI.SD];
    ZD(j,:) = [RIG.ZD RI.ZD]./VT;
    
%     %%% CDS Measures
    Hajn = nan(size(IGTainn{j}));
    Hajn(~isnan(IGTainn{j})) = Haj; %to maitain original timestamps.
    Hpjn = nan(size(IGTcinn{j}));
    Hpjn(~isnan(IGTcinn{j})) = Hpj;
    Haj = Hajn; Hpj=Hpjn;

    [THjt] = DiarizeCDS(Vi{j},Hpj,Haj,Ami{j},fv);
    CM = CDSMeasures(THjt);
    CMG = CDSMeasures(Rtc{j});
    NU(j,:) = [CMG.NU CM.NU]./VT;
    NW(j,:) = [CMG.NW CM.NW]./VT;
    WC(j,:) = [CMG.WC CM.WC]./VT;
    TTR(j,:) = [CMG.TTR CM.TTR]./VT;
    SMLU(j,:) = [CMG.MLU CM.MLU]./VT;
    
    %%% Ground truth measures
    [THjtg] = DiarizeCDS(Vi{j},IGTcinn{j},IGTainn{j},Ami{j},fv);
    CMGG = CDSMeasures(THjtg);
    NUG(j,:) = [CMG.NU CMGG.NU]./VT;
    NWG(j,:) = [CMG.NW CMGG.NW]./VT;
    WCG(j,:) = [CMG.WC CMGG.WC]./VT;
    TTRG(j,:) = [CMG.TTR CMGG.TTR]./VT;
    SMLUG(j,:) = [CMG.MLU CMGG.MLU]./VT;
    
    Hab{j} = Haj;
    Hpb{j} = Hpj;
    
end
toc

%% Measures
CMAs = sum(CMA,3);
CMPs = sum(CMP,3);

PrA = CMAs(1,1)/(CMAs(1,1)+CMAs(1,2)); %precision
ReA = CMAs(1,1)/(CMAs(1,1)+CMAs(2,1)); %recall
FsA = 2*PrA*ReA/(PrA+ReA); %F-score
AcA = (CMAs(1,1)+CMAs(2,2))/(CMAs(1,1)+CMAs(2,2)+CMAs(1,2)+CMAs(2,1)); %Accuracy

PFA = [AcA PrA ReA FsA Ka];

PrP = CMPs(1,1)/(CMPs(1,1)+CMPs(1,2)); %precision
ReP = CMPs(1,1)/(CMPs(1,1)+CMPs(2,1)); %recall
FsP = 2*PrP*ReP/(PrP+ReP); %F-score
AcP = (CMPs(1,1)+CMPs(2,2))/(CMPs(1,1)+CMPs(2,2)+CMPs(1,2)+CMPs(2,1)); %Accuracy

PFP = [AcP PrP ReP FsP Kp];

%%% Aggregate measures
MA.FI = [FI(:,1) FI(:,3)];
MA.ND = [ND(:,1) ND(:,3)];
MA.ZD = [ZD(:,1) ZD(:,3)];
MA.NU = [NU(:,1) NU(:,4)];
MA.NW = [NW(:,1) NW(:,4)];
MA.WC = [WC(:,1) WC(:,4)];
MA.MLU = fillmissing([SMLU(:,1) SMLU(:,4)],'constant',0);
MA.TTR = fillmissing([TTR(:,1) TTR(:,4)],'constant',0);
MA.NUG = [NUG(:,1) NUG(:,4)];
MA.NWG = [NWG(:,1) NWG(:,4)];
MA.WCG = [WCG(:,1) WCG(:,4)];
MA.MLUG = fillmissing([SMLUG(:,1) SMLUG(:,4)],'constant',0);
MA.TTRG = fillmissing([TTRG(:,1) TTRG(:,4)],'constant',0);

MP.FI = [FI(:,2) FI(:,4)];
MP.ND = [ND(:,2) ND(:,4)];
MP.ZD = [ZD(:,2) ZD(:,4)];
MP.NU = [NU(:,2) NU(:,5)];
MP.NW = [NW(:,2) NW(:,5)];
MP.WC = [WC(:,2) WC(:,5)];
MP.MLU = fillmissing([SMLU(:,2) SMLU(:,5)],'constant',0);
MP.TTR = fillmissing([TTR(:,2) TTR(:,5)],'constant',0);
MP.NUG = [NUG(:,2) NUG(:,5)];
MP.NWG = [NWG(:,2) NWG(:,5)];
MP.WCG = [WCG(:,2) WCG(:,5)];
MP.MLUG = fillmissing([SMLUG(:,2) SMLUG(:,5)],'constant',0);
MP.TTRG = fillmissing([TTRG(:,2) TTRG(:,5)],'constant',0);

MF.FI = [FI(:,2)+FI(:,1) FI(:,4)+FI(:,3)]; %aggregate frequency
MF.ND = [mean([ND(:,2),ND(:,1)],2) mean([ND(:,4),ND(:,3)],2)]; %Revise if it is going to be used
MF.ZD = [ZD(:,2)+ZD(:,1) ZD(:,4)+ZD(:,3)];
MF.NU = [NU(:,3) NU(:,6)];
MF.NW = [NW(:,3) NW(:,6)];
MF.WC = [WC(:,3) WC(:,6)];
MF.MLU = fillmissing([SMLU(:,3) SMLU(:,6)],'constant',0);
MF.TTR = fillmissing([TTR(:,3) TTR(:,6)],'constant',0);
MF.NUG = [NUG(:,3) NUG(:,6)];
MF.NWG = [NWG(:,3) NWG(:,6)];
MF.WCG = [WCG(:,3) WCG(:,6)];
MF.MLUG = fillmissing([SMLUG(:,3) SMLUG(:,6)],'constant',0);
MF.TTRG = fillmissing([TTRG(:,3) TTRG(:,6)],'constant',0);

%%% Adaptation using OLP
[MAn,EAn,RAn] = LOSOadapt(MA); 
[MPn,EPn,RPn] = LOSOadapt(MP);
[MFn,EFn,RFn] = LOSOadapt(MF);

PA = [median(EAn.NU) median(EAn.WC) median(EAn.NW) median(EAn.MLU) median(EAn.TTR) RAn.NU RAn.WC RAn.NW RAn.MLU RAn.TTR];
PP = [median(EPn.NU) median(EPn.WC) median(EPn.NW) median(EPn.MLU) median(EPn.TTR) RPn.NU RPn.WC RPn.NW RPn.MLU RPn.TTR];
PF = [median(EFn.NU) median(EFn.WC) median(EFn.NW) median(EFn.MLU) median(EFn.TTR) RFn.NU RFn.WC RFn.NW RFn.MLU RFn.TTR];

PM = [PFA PFP PA PP PF]; %Final performance metric

%% Training on all data, testing RI and L measures
clear NUk MLUk NWk FIk MDk NDk SDk OPk ZDk
clear ERR_FIk Rfik  ERR_NDk Rndk  ERR_NUk Rnuk ERR_NWk Rnwk

XTrain = Si';
YTrainAI = IGTai';
YTrainPI = IGTci';
netAIt = trainNetwork(XTrain,YTrainAI,layers,options);
netPIt = trainNetwork(XTrain,YTrainPI,layers,options);

for k=1:numel(ChVec)
    YPredAI = classify(netAIt,Si{k});
    YPredPI = classify(netPIt,Si{k});
    YPredAI = double(YPredAI); 
    YPredPI = double(YPredPI);  
    
    Hak = YPredAI'-1;
    Hpk = YPredPI'-1;
    
    IGTak = double(IGTai{k}')-1; IGTpk = double(IGTci{k}')-1; %clean
    %%%Errors
    CMAk(:,:,k) = confusionmat(IGTak,Hak); %confusion matrix
    CMPk(:,:,k) = confusionmat(IGTpk,Hpk);
    
    %%% RI Measures
    RIk = RIMeasures(Hak,Hpk,fv);
    RIGk = RIMeasures(IGTak,IGTpk,fv);
    FIk(k,:) = [RIGk.FI RIk.FI]./VT;
    MDk(k,:) = [RIGk.MD RIk.MD];
    NDk(k,:) = [RIGk.ND RIk.ND];
    SDk(k,:) = [RIGk.SD RIk.SD];
    ZDk(k,:) = [RIGk.ZD RIk.ZD]./VT;
    
    %%% CDS Measures
    Hakn = nan(size(IGTainn{k}));
    Hakn(~isnan(IGTainn{k})) = Hak; %to maitain original timestamps. -1 to convert to 0 1 again
    Hpkn = nan(size(IGTcinn{k}));
    Hpkn(~isnan(IGTcinn{k})) = Hpk;
    Hak=Hakn; Hpk = Hpkn;

    [THk] = DiarizeCDS(Vi{k},Hpk,Hak,Ami{k},fv);
    CMk = CDSMeasures(THk);
    CMGk = CDSMeasures(Rtc{k});
    NUk(k,:) = [CMGk.NU CMk.NU]./VT;
    NWk(k,:) = [CMGk.NW CMk.NW]./VT;
    WCk(k,:) = [CMGk.WC CMk.WC]./VT;
    TTRk(k,:) = [CMGk.TTR CMk.TTR]./VT;
    SMLUk(k,:) = [CMGk.MLU CMk.MLU]./VT;
    Hpbk{k} = Hpk;
end

CMAks = sum(CMAk,3);
CMPks = sum(CMPk,3);

PrAk = CMAks(1,1)/(CMAks(1,1)+CMAks(1,2)); %precision
ReAk = CMAks(1,1)/(CMAks(1,1)+CMAks(2,1)); %recall
FsAk = 2*PrAk*ReAk/(PrAk+ReAk); %F-score
AcAk = (CMAks(1,1)+CMAks(2,2))/(CMAks(1,1)+CMAks(2,2)+CMAks(1,2)+CMAks(2,1)); %Accuracy
PFAk = [AcAk PrAk ReAk FsAk Kak];

PrPk = CMPks(1,1)/(CMPks(1,1)+CMPks(1,2)); %precision
RePk = CMPks(1,1)/(CMPks(1,1)+CMPks(2,1)); %recall
FsPk = 2*PrPk*RePk/(PrPk+RePk); %F-score
AcPk = (CMPks(1,1)+CMPks(2,2))/(CMPks(1,1)+CMPks(2,2)+CMPks(1,2)+CMPks(2,1)); %Accuracy
PFPk = [AcPk PrPk RePk FsPk Kpk];

%%% Aggregate measures
MAk.FI = [FIk(:,1) FIk(:,3)];
MAk.ND = [NDk(:,1) NDk(:,3)];
MAk.SD = [SDk(:,1) SDk(:,3)];
MAk.ZD = [ZDk(:,1) ZDk(:,3)];
MAk.NU = [NUk(:,1) NUk(:,4)];
MAk.NW = [NWk(:,1) NWk(:,4)];
MAk.WC = [WCk(:,1) WCk(:,4)];
MAk.MLU = fillmissing([SMLUk(:,1) SMLUk(:,4)],'constant',0);
MAk.TTR = fillmissing([TTRk(:,1) TTRk(:,4)],'constant',0);

MPk.FI = [FIk(:,2) FIk(:,4)];
MPk.ND = [NDk(:,2) NDk(:,4)];
MPk.SD = [SDk(:,2) SDk(:,4)];
MPk.ZD = [ZDk(:,2) ZDk(:,4)];
MPk.NU = [NUk(:,2) NUk(:,5)];
MPk.NW = [NWk(:,2) NWk(:,5)];
MPk.WC = [WCk(:,2) WCk(:,5)];
MPk.MLU = fillmissing([SMLUk(:,2) SMLUk(:,5)],'constant',0);
MPk.TTR = fillmissing([TTRk(:,2) TTRk(:,5)],'constant',0);

MFk.FI = [FIk(:,2)+FIk(:,1) FIk(:,4)+FIk(:,3)]; %aggregate frequency
MFk.ND = [mean([NDk(:,2),ND(:,1)],2) mean([NDk(:,4),NDk(:,3)],2)]; %Revise if it is going to be used
MFk.SD = [mean([SDk(:,2),SD(:,1)],2) mean([SDk(:,4),SDk(:,3)],2)]; %Revise if it is going to be used
MFk.ZD = [ZDk(:,2)+ZDk(:,1) ZDk(:,4)+ZDk(:,3)];
MFk.NU = [NUk(:,3) NUk(:,6)];
MFk.NW = [NWk(:,3) NWk(:,6)];
MFk.WC = [WCk(:,3) WCk(:,6)];
MFk.MLU = fillmissing([SMLUk(:,3) SMLUk(:,6)],'constant',0);
MFk.TTR = fillmissing([TTRk(:,3) TTRk(:,6)],'constant',0);


%%% Adaptation
[MAkn,EAkn,RAkn,ADa] = Kadapt(MAk); %Measures, errors
[MPkn,EPkn,RPkn,ADp] = Kadapt(MPk);
[MFkn,EFkn,RFkn,ADf] = Kadapt(MFk);

PAk = [median(EAkn.NU) median(EAkn.WC) median(EAkn.NW) median(EAkn.MLU) median(EAkn.TTR) RAkn.NU RAkn.WC RAkn.NW RAkn.MLU RAkn.TTR];
PPk = [median(EPkn.NU) median(EPkn.WC) median(EPkn.NW) median(EPkn.MLU) median(EPkn.TTR) RPkn.NU RPkn.WC RPkn.NW RPkn.MLU RPkn.TTR];
PFk = [median(EFkn.NU) median(EFkn.WC) median(EFkn.NW) median(EFkn.MLU) median(EFkn.TTR) RFkn.NU RFkn.WC RFkn.NW RFkn.MLU RFkn.TTR];

PMk = [PFAk PFPk PAk PPk PFk]; %Final performance metric


%%% Plot
k=3;
MSEc = nanmean((IGTcinn{k}-Hpbk{k}).^2);
MSEa = nanmean((IGTainn{k}-Habk{k}).^2);
figure
subplot(2,2,1)
plot(0:1/fv:(numel(IGTainn{k})-1)/fv,IGTainn{k})
axis([0 (numel(IGTainn{k})-1)/fv -0.1 1.1])
title('Reference Adult Interaction')
subplot(2,2,3)
plot(0:1/fv:(numel(Habk{k})-1)/fv,Habk{k})
axis([0 (numel(Habk{k})-1)/fv -0.1 1.1])
title(['Predicted Adult Interaction- Error ',num2str(MSEa)])
subplot(2,2,2)
plot(0:1/fv:(numel(IGTcinn{k})-1)/fv,IGTcinn{k})
axis([0 (numel(IGTcinn{k})-1)/fv -0.1 1.1])
title('Reference Peer Interaction')
subplot(2,2,4)
plot(0:1/fv:(numel(Hpbk{k})-1)/fv,Hpbk{k})
axis([0 (numel(Hpbk{k})-1)/fv -0.1 1.1])
title(['Predicted Peer Interaction - Error ',num2str(MSEc)])

%%% Ground truth results
GTv = [1 2 3 4 5 8 10 11 13]; %id for recurring kids
%GTv = 1:13; %All kids
R.MA.FI = FIk(GTv,1);
R.MA.ND = NDk(GTv,1);
R.MA.SD = SDk(GTv,1);
R.MA.ZD = ZDk(GTv,1);
R.MA.NU = NUk(GTv,1);
R.MA.ML = SMLUk(GTv,1);
R.MA.TR = TTRk(GTv,1);
R.MA.NW = NWk(GTv,1);
R.MA.WC = WCk(GTv,1);

R.MP.FI = FIk(GTv,2);
R.MP.ND = NDk(GTv,2);
R.MP.SD = SDk(GTv,2);
R.MP.ZD = ZDk(GTv,2);
R.MP.NU = NUk(GTv,2);
R.MP.ML = SMLUk(GTv,2);
R.MP.TR = TTRk(GTv,2);
R.MP.NW = NWk(GTv,2);
R.MP.WC = WCk(GTv,2);

R.MF.FI = FIk(GTv,2)+FIk(GTv,1);
R.MF.ND = mean([NDk(GTv,2),NDk(GTv,1)],2);
R.MF.SD = mean([SDk(GTv,2),SDk(GTv,2)],2);
R.MF.ZD = ZDk(GTv,2)+ZDk(GTv,1);
R.MF.NU = NUk(GTv,3);
R.MF.ML = SMLUk(GTv,3);
R.MF.TR = TTRk(GTv,3);
R.MF.NW = NWk(GTv,3);
R.MF.WC = WCk(GTv,3);


fname='Data/GT_FallMorning.mat';

DL.netAI= netAIt;
DL.netPI= netPIt;
AD.a = ADa;
AD.p = ADp;
AD.f = ADf;

%save(fname,'R'); %save ground truth
% save('Data/ADP_MB.mat','AD'); %save adaptation
% save('Data/DL_RMB.mat','DL'); %save classifiers