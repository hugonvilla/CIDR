clear

%%%%%%%%%%%%%%%%%%
%%%% Audio Feature Extraction
%%%%%%%%%%%%%%%%%%

%% Get Files
ChVec=string(['14']); 
Vchf=16*ones(1,numel(ChVec));
Vcho=1*ones(1,numel(ChVec));


Mdir = '/Users/PathtoAudio'; 


for i=1:numel(ChVec)

    Child=ChVec(i);
    
    for j = Vcho(i):Vchf(i)  
        Nvid = j;
        Vfile = strcat(Mdir,'/Video/C',Child,'P',num2str(Nvid),'V.MP4'); %path to video file
        AUjson = strcat(Mdir,'/DiarHTTranscripts/C',Child,'P',num2str(Nvid),'AUN10_SPKID.json'); %diarized audio json
        AUwrite = strcat(Mdir,'/AudioFeatures/C',Child,'P',num2str(Nvid),'SPFEAT.json'); %audiofeat json

        %% Parse Transcript
        fid = fopen(AUjson,'r');
        raw = fread(fid);str = char(raw');fclose(fid);
        valAU=jsondecode(str);clear raw str
        Ams = struct2cell(valAU.results.speaker_labels.segments); %non-diarized
        Am = ParseAudioTrans(Ams); %features and labels
        Amd = struct2table(valAU.results.diarized); %diarized
        Amd((Amd{:,3}-Amd{:,1}) < (1/29.97),:)=[]; %delete short utterances

        if size(Am,1)==size(Amd,1) %copy labeled speaker
            Am(:,6)=Amd(:,end); %5 on old, 6 on new
        else
            disp('Error, no agreement with Diar')
            return
        end

        %% Acoustic Feature Extract
        [au,fsa] = audioread(Vfile); %read audio
        for k =1:size(Am,1)
            t0=Am{k,1};
            tf=Am{k,3};
            AUw =  au(t0*fsa+1:min(tf*fsa,size(au,1)),1);
            Ld{k} = acousticLoudness(AUw,fsa,'TimeVarying',true); %loudness
        end
        Am(:,7) = Ld';
        clear Ld


        %% Rewrite Json file

        valAU.results.diarized=Am;
        jsonStr = jsonencode(valAU);
        fid = fopen(AUwrite,'w');
        if fid == -1, error('Cannot create JSON file'); end
        fwrite(fid, jsonStr, 'char');
        fclose(fid);
    end
    i
end




