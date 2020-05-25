function [TR] = GTTranscriptParser(GTtrans)
    %% Process ground truth
    RTr = readtable(GTtrans,'ReadVariableNames',false);
    RTr(1:9,:) = []; %delete non-transcription
    RTr = RTr(:,1); %in case there are two columns
    RTr(end)=[]; %delete non-transcription.
    Rta = []; Rtp = []; Rtc=[];
    for i=1:numel(RTr)
        str = RTr{i};
        str = lower(str);
        str = eraseBetween(str,"[","]",'Boundaries','inclusive'); %erase coding
        str = eraseBetween(str,"(",")",'Boundaries','inclusive'); %erase mazes
        str = eraseBetween(str,"{","}",'Boundaries','inclusive'); %erase meaningful vocalizations
        str = erase(str,["xxx","xx","x"]); %erase unintelligible segments
        str = erasePunctuation(str); 
        if isempty(str)==0 && strcmp(str(1),'t')==1
            str = eraseBetween(str,1,2,'Boundaries','inclusive');
            str = strip(str);
            if isempty(str)==0 
                Rta = [Rta;string(str)]; %concatenate adult string
            end
        elseif isempty(str)==0 && strcmp(str(1),'p')==1
            str = eraseBetween(str,1,2,'Boundaries','inclusive');
            str = strip(str);
            if isempty(str)==0 
                Rtp = [Rtp;string(str)]; %concatenate peer string
            end
        elseif isempty(str)==0 && strcmp(str(1),'c')==1
            str = eraseBetween(str,1,2,'Boundaries','inclusive');
            str = strip(str);
            if isempty(str)==0 
                Rtc = [Rtc;string(str)]; %concatenate focal child string
            end
        end
    end
    
    TR.Gta = Rta;
    TR.Gtp = Rtp;
    TR.Gtc = Rtc;
   
    
    
    
    
    
    
