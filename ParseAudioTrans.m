function [Am] = ParseAudioTrans(Ams)
%%%% Parses transcript from Amazon Transcribe
warning off
clear Am
k=1;
for i = 1:size(Ams,2) %%%% This re-segments the segments using punctuation
    Wi = {Ams{5,i}.words}.';
    Ci = {Ams{5,i}.confidence}.';
    To = 1; %initial start time index
    %for j=size(Wi,1) %no utterance segmentation
    for j=1:size(Wi,1) %utterance segmentation
        if sum(contains(Wi{j},[".","?",";",":"]))>=1 || j == size(Wi,1) %if breaking punct or last item
            Am{1,k} = [Ams{5, i}(To).start_time].'; %initial time
            Am{2,k} = str2double(Ams{2,i}(5:end))+1; %speaker string to number, +1 to account for zeroth person
            Am{3,k} = [Ams{5, i}(j).end_time].'; %final time
            h = string(Wi(To:j));
            h = lower(h);
            h=strrep(h,'''s',' is');
            h=strrep(h,'''re',' are');
            h=strrep(h,'''m',' am');
            h=strrep(h,'''ll',' will');
            h=strrep(h,'can''t',' not');
            h=strrep(h,'n''t',' not'); 
            h=strrep(h,'gonna','going to'); 
            h=strrep(h,'wanna','want to'); 
            h=strrep(h,'gotta','got to'); 
            h = erasePunctuation(h); 
            h(h=="") = [];%utterance's words
            Am{4,k} = join(h); %segment scalar string
            %%% Delete very-short utterances not considered in diarization
            if (Am{3,k} - Am{1,k}) < (1/29.97)
                Am{4,k} = missing;
            end
            c= [Ci{To:j}]; %extract confidence vector
            Am{5,k} = mean(c(c > 0)); %exclude punctuations
            k=k+1; %move to next
            To = j+1; %move to next
        end
    end
end

Am = cell2table(Am');
Am = rmmissing(Am,1); %removes missing transcriptions
