function [Mn,En,Rn,PD] = LOSOadapt(varargin) %varargin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Measure adaptation script
%%%% flag = 0: no adaptation
%%%% flag = 1: OLS
%%%% flag = 2: OLP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
M = varargin{1};

Nf = size(M.NU,1);
Mn = M; % no adaptation

for j = 1:Nf
    InTest=1:Nf;InTest(j)=[];
    mdl =gmregress(M.FI(InTest,2),M.FI(InTest,1));
    Mn.FI(j,2) = mdl(1)+mdl(2)*M.FI(j,2);
    mdl =gmregress(M.ND(InTest,2),M.ND(InTest,1));
    Mn.ND(j,2) = mdl(1)+mdl(2)*M.ND(j,2);
    mdl =gmregress(M.SD(InTest,2),M.SD(InTest,1));
    Mn.SD(j,2) = mdl(1)+mdl(2)*M.SD(j,2);
    mdl =gmregress(M.ZD(InTest,2),M.ZD(InTest,1));
    Mn.ZD(j,2) = mdl(1)+mdl(2)*M.ZD(j,2);
    mdl =gmregress(M.NU(InTest,2),M.NU(InTest,1));
    Mn.NU(j,2) = mdl(1)+mdl(2)*M.NU(j,2);
    mdl =gmregress(M.NW(InTest,2),M.NW(InTest,1));
    Mn.NW(j,2) = mdl(1)+mdl(2)*M.NW(j,2);
    mdl =gmregress(M.WC(InTest,2),M.WC(InTest,1));
    Mn.WC(j,2) = mdl(1)+mdl(2)*M.WC(j,2);

    mdl =gmregress(M.MLU(InTest,2),M.MLU(InTest,1));
    Mn.MLU(j,2) = mdl(1)+mdl(2)*M.MLU(j,2);
    mdl =gmregress(M.TTR(InTest,2),M.TTR(InTest,1));
    Mn.TTR(j,2) = mdl(1)+mdl(2)*M.TTR(j,2);

    mdl =gmregress(M.NUG(InTest,2),M.NUG(InTest,1));
    Mn.NUG(j,2) = mdl(1)+mdl(2)*M.NUG(j,2);
    mdl =gmregress(M.NWG(InTest,2),M.NWG(InTest,1));
    Mn.NWG(j,2) = mdl(1)+mdl(2)*M.NWG(j,2);
    mdl =gmregress(M.WCG(InTest,2),M.WCG(InTest,1));
    Mn.WCG(j,2) = mdl(1)+mdl(2)*M.WCG(j,2);

    Mn.MLUG(j,2) = Mn.WCG(j,2)/Mn.NUG(j,2);
    Mn.TTRG(j,2) = Mn.NWG(j,2)/Mn.WCG(j,2);    
end


%% Errors
En.FI = abs(Mn.FI(:,1)-Mn.FI(:,2))./Mn.FI(:,1);
En.ND = abs(Mn.ND(:,1)-Mn.ND(:,2))./Mn.ND(:,1);
En.SD = abs(Mn.SD(:,1)-Mn.SD(:,2))./Mn.SD(:,1);
En.ZD = abs(Mn.ZD(:,1)-Mn.ZD(:,2))./Mn.ZD(:,1);
En.NU = abs(Mn.NU(:,1)-Mn.NU(:,2))./Mn.NU(:,1);
En.NW = abs(Mn.NW(:,1)-Mn.NW(:,2))./Mn.NW(:,1);
En.WC = abs(Mn.WC(:,1)-Mn.WC(:,2))./Mn.WC(:,1);
En.MLU = abs(Mn.MLU(:,1)-Mn.MLU(:,2))./Mn.MLU(:,1);
En.TTR = abs(Mn.TTR(:,1)-Mn.TTR(:,2))./Mn.TTR(:,1);
En.NUG = abs(Mn.NUG(:,1)-Mn.NUG(:,2))./Mn.NUG(:,1);
En.NWG = abs(Mn.NWG(:,1)-Mn.NWG(:,2))./Mn.NWG(:,1);
En.WCG = abs(Mn.WCG(:,1)-Mn.WCG(:,2))./Mn.WCG(:,1);
En.MLUG = abs(Mn.MLUG(:,1)-Mn.MLUG(:,2))./Mn.MLUG(:,1);
En.TTRG = abs(Mn.TTRG(:,1)-Mn.TTRG(:,2))./Mn.TTRG(:,1);

ERn.FI = (Mn.FI(:,1)-Mn.FI(:,2))./Mn.FI(:,1);
ERn.ND = (Mn.ND(:,1)-Mn.ND(:,2))./Mn.ND(:,1);
ERn.SD = (Mn.SD(:,1)-Mn.SD(:,2))./Mn.SD(:,1);
ERn.ZD = (Mn.ZD(:,1)-Mn.ZD(:,2))./Mn.ZD(:,1);
ERn.NU = (Mn.NU(:,1)-Mn.NU(:,2))./Mn.NU(:,1);
ERn.NW = (Mn.NW(:,1)-Mn.NW(:,2))./Mn.NW(:,1);
ERn.WC = (Mn.WC(:,1)-Mn.WC(:,2))./Mn.WC(:,1);
ERn.MLU = (Mn.MLU(:,1)-Mn.MLU(:,2))./Mn.MLU(:,1);
ERn.TTR = (Mn.TTR(:,1)-Mn.TTR(:,2))./Mn.TTR(:,1);
ERn.NUG = (Mn.NUG(:,1)-Mn.NUG(:,2))./Mn.NUG(:,1);
ERn.NWG = (Mn.NWG(:,1)-Mn.NWG(:,2))./Mn.NWG(:,1);
ERn.WCG = (Mn.WCG(:,1)-Mn.WCG(:,2))./Mn.WCG(:,1);
ERn.MLUG = (Mn.MLUG(:,1)-Mn.MLUG(:,2))./Mn.MLUG(:,1);
ERn.TTRG = (Mn.TTRG(:,1)-Mn.TTRG(:,2))./Mn.TTRG(:,1);

%% Correlations
[Rn.FI,Rn.FIp] = corr(Mn.FI(:,1),Mn.FI(:,2));
[Rn.ND,Rn.NDp] = corr(Mn.ND(:,1),Mn.ND(:,2));
[Rn.SD,Rn.SDp] = corr(Mn.SD(:,1),Mn.SD(:,2));
[Rn.ZD,Rn.ZDp] = corr(Mn.ZD(:,1),Mn.ZD(:,2));
[Rn.NU,Rn.NUp] = corr(Mn.NU(:,1),Mn.NU(:,2));
[Rn.NW,Rn.NWp] = corr(Mn.NW(:,1),Mn.NW(:,2));
[Rn.WC,Rn.WCp] = corr(Mn.WC(:,1),Mn.WC(:,2));
[Rn.MLU,Rn.MLUp] = corr(Mn.MLU(:,1),Mn.MLU(:,2));
[Rn.TTR,Rn.TTRp] = corr(Mn.TTR(:,1),Mn.TTR(:,2));
[Rn.NUG,Rn.NUGp] = corr(Mn.NUG(:,1),Mn.NUG(:,2));
[Rn.NWG,Rn.NWGp] = corr(Mn.NWG(:,1),Mn.NWG(:,2));
[Rn.WCG,Rn.WCGp] = corr(Mn.WCG(:,1),Mn.WCG(:,2));
[Rn.MLUG,Rn.MLUGp] = corr(Mn.MLUG(:,1),Mn.MLUG(:,2));
[Rn.TTRG,Rn.TTRGp] = corr(Mn.TTRG(:,1),Mn.TTRG(:,2));

%% Metrics

PD= [median(En.WCG),min(En.WCG),max(En.WCG),mean(En.WCG),Rn.WCG,median(En.NWG),min(En.NWG),max(En.NWG),mean(En.NWG),Rn.NWG,median(En.MLUG),min(En.MLUG),max(En.MLUG),mean(En.MLUG),Rn.MLUG,median(En.TTRG),min(En.TTRG),max(En.TTRG),mean(En.TTRG),Rn.TTRG;
     median(En.WC),min(En.WC),max(En.WC),mean(En.WC),Rn.WC,median(En.NW),min(En.NW),max(En.NW),mean(En.NW),Rn.NW,median(En.MLU),min(En.MLU),max(En.MLU),mean(En.MLU),Rn.MLU,median(En.TTR),min(En.TTR),max(En.TTR),mean(En.TTR),Rn.TTR];
     
     
     
     
     
     
    