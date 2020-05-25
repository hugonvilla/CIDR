function [IGTak,IGTck,IGTlk] = CodingParser(GTint,Sk,fv)
% Process Interaction manual labels from .csv file (Datavyu)
Gall = readtable(GTint);
Gcen = Gall(:,2:4); %center time variable
Gact = Gall(:,6:8); %activity 
Gacto = {0,Gact{1,1},'no'}; %add inital no
Gact = [Gacto;Gact];

if size(Gall,2) > 8 %if fall morning
    Gia = Gall(:,10:12); %adult interaction
    Gic = Gall(:,26:28); %peer interaction
    Ggro = Gall(:,22:24); %grouping
    Gloc = Gall(:,14:16); %center time location
    Gloco = {0,Gloc{1,1},'na'}; %add inital na
    Gloc = [Gloco;Gloc];
else
    Gia = array2table(nan(size(Gall,1),3));
    Gic=array2table(nan(size(Gall,1),3));
    Ggro=array2table(nan(size(Gall,1),3));
    Gloc=array2table(nan(size(Gall,1),3));
end

Taia=[]; Taic=[]; Toff=[]; Tcen=[]; Tloc=[]; %on-off table for adult and peer interactions and off time in ms
for k = 1:size(Gall,1) %because matlab fills both Gia or Gic with nans until the last row
    if strcmp(string(Gia{k,3}),'no') == 0 %if not "no interaction" for aduld
        Taia=[Taia;Gia{k,1:2}];
    end
    if strcmp(string(Gic{k,3}),'co') == 1 %if "cooperation (reciprocal)" interaction for peers
        Taic=[Taic;Gic{k,1:2}];
    end
    if strcmp(string(Gact{k,3}),'no') == 1 %|| strcmp(string(Ggro{k,3}),'wl') == 1 %|| strcmp(string(Gact{k,3}),'ot') == 1  %if recording is not valid
        Toff = [Toff;Gact{k,1:2}];
    end
    if strcmp(string(Gcen{k,3}),'no') == 1
        Tcen = [Tcen;Gcen{k,1:2}];
    end
    
    Tloc = [Tloc;Gloc{k,1:2}];
    
    if strcmp(string(Gloc{k,3}),'wr') == 1
        Gloc{k,4} = 1;
    elseif strcmp(string(Gloc{k,3}),'bl') == 1
        Gloc{k,4} = 2;
    elseif strcmp(string(Gloc{k,3}),'bk') == 1
        Gloc{k,4} = 3;
    elseif strcmp(string(Gloc{k,3}),'sn') == 1
        Gloc{k,4} = 4;
    elseif strcmp(string(Gloc{k,3}),'ar') == 1
        Gloc{k,4} = 5;
    elseif strcmp(string(Gloc{k,3}),'sm') == 1
        Gloc{k,4} = 6;
    elseif strcmp(string(Gloc{k,3}),'dr') == 1
        Gloc{k,4} = 7;
    elseif strcmp(string(Gloc{k,3}),'lg') == 1
        Gloc{k,4} = 8;
    elseif strcmp(string(Gloc{k,3}),'ot') == 1
        Gloc{k,4} = 9;
    else
        Gloc{k,4} = 0;
    end
end
Tloc(isnan(Tloc(:,1)),:)=[];



%%% from tables to vectors
IGTak = zeros(Sk,1);
tian = min(round((Taia/1000+(1/fv))*fv),Sk); %convert table to time indices. +1 not needed for Amazon
for k=1:size(tian,1) %number of rows
    IGTak(tian(k,1):tian(k,2))=1;
end

IGTck = zeros(Sk,1);
ticn = min(round((Taic/1000+(1/fv))*fv),Sk); %convert table to time indices. +1 not needed for Amazon
for k=1:size(ticn,1) %number of rows
    IGTck(ticn(k,1):ticn(k,2))=1;
end

IGTlk = zeros(Sk,1);
tilo = min(round((Tloc/1000+(1/fv))*fv),Sk);
for k = 1:size(tilo,1)
    IGTlk(tilo(k,1):tilo(k,2)) = Gloc{k,4};
end

%%% Delete periods
toffn = min(round((Toff/1000+(1/fv))*fv),Sk); %delete off periods
for k=1:size(toffn,1) %number of rows
    IGTak(toffn(k,1):toffn(k,2))=nan; % "delete" off-periods
    IGTck(toffn(k,1):toffn(k,2))=nan;
    IGTlk(toffn(k,1):toffn(k,2))=nan;
end

tcenn = min(round((Tcen/1000+(1/fv))*fv),Sk); %delete non-center time
for k=1:size(tcenn,1) %number of rows
    IGTak(tcenn(k,1):tcenn(k,2))=nan; % "delete" non-center time
    IGTck(tcenn(k,1):tcenn(k,2))=nan;
    IGTlk(tcenn(k,1):tcenn(k,2))=nan;
end



