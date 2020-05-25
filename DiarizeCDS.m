function [TH] = DiarizeCDS(Vk,Zkc,Zka,Amk,fv)
clear Dvc Dva 
Zkc(isnan(Zkc))=0; %because this tool doesn't consider nans
Zka(isnan(Zka))=0;
Htp=[]; Htf=[];Hta=[];

%%% With Amazon Transcribe
for i = 1:size(Amk,1) %for each speech segment
    kov = round(Amk{i,1}*fv)+1;  %index of initial time of segment
    kfv = round(min(Amk{i,3}*fv,size(Vk,1))); %index of final time of segment
    Dvc = sum(Zkc(kov:kfv)); %*(1-Waz); %*diag(Wav)
    Dva= sum(Zka(kov:kfv)); %*Waz;
    if Dvc > 0 %If interaction with peer occurred during utterance
        if Amk{i,6} == 3 % if peer
            Htp = [Htp;Amk{i,4}];
        elseif Amk{i,6}  == 2 %if focal child
            Htf = [Htf;Amk{i,4}];
        end
    end
    if Dva > 0 %If interaction with adult occurred during utterance
        if Amk{i,6} == 1 % if adult
            Hta = [Hta;Amk{i,4}];
        elseif Amk{i,6}  == 2 %if focal child
            Htf = [Htf;Amk{i,4}];
        end
    end
end
          

TH.ta = Hta;
TH.tp = Htp;
TH.tf = Htf;

    