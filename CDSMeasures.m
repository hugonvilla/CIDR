function [CM] = CDSMeasures(Htck)

    %% Peer CDS 
    clear Lup Htp Htps Htpj
    Htp = Htck.tp;
    if isempty(Htp) == 0
        TokHp = tokenizedDocument(Htp);
        NUHZp = numel(TokHp);
        Htpj = strjoin(Htp);
        Htps = strsplit(Htpj);
        NWHZp = numel(unique(Htps)); %number of unique words
        WCHp = numel(Htps);
    else
        NUHZp=0;NWHZp=0;WCHp = 0;
    end
    
    %% Adult CDS
    clear Lua Hta Htas Htaj
    Hta = Htck.ta;
    if isempty(Hta) == 0
        TokHa = tokenizedDocument(Hta);
        NUHZa = numel(TokHa);
        Htaj = strjoin(Hta);
        Htas = strsplit(Htaj);
        NWHZa = numel(unique(Htas)); %number of unique words
        WCHa = numel(Htas);
    else
       NUHZa = 0;NWHZa=0;WCHa = 0;
    end
    
    %% Focal Child CDS
    clear Luf Htf Htfs Htfj
    Htf = Htck.tf;
    if isempty(Htf) == 0
        TokHf = tokenizedDocument(Htf);
        NUHZf = numel(TokHf);
        Htfj = strjoin(Htf);
        Htfs = strsplit(Htfj);
        NWHZf = numel(unique(Htfs)); %number of unique words
        WCHf = numel(Htfs);
    else
       NUHZf = 0; NWHZf=0;WCHf = 0;
    end


CM.NU = [NUHZa' NUHZp' NUHZf']; %Peer & Adult number of utterance for Reference, Amazon, VAD
CM.NW = [NWHZa' NWHZp' NWHZf']; %Peer & Adult number of unique words for reference and amazon
CM.WC = [WCHa' WCHp' WCHf'];



