function [Mn,En,Rn,AD] = Kadapt(M)
Mn = M;
AD=[];


AD.mdlFI =gmregress(M.FI(:,2),M.FI(:,1));
Mn.FI(:,2) = AD.mdlFI(1)+AD.mdlFI(2)*M.FI(:,2);
AD.mdlND =gmregress(M.ND(:,2),M.ND(:,1));
Mn.ND(:,2) = AD.mdlND(1)+AD.mdlND(2)*M.ND(:,2);
AD.mdlSD =gmregress(M.SD(:,2),M.SD(:,1));
Mn.SD(:,2) = AD.mdlSD(1)+AD.mdlSD(2)*M.SD(:,2);
AD.mdlZD =gmregress(M.ZD(:,2),M.ZD(:,1));
Mn.ZD(:,2) = AD.mdlZD(1)+AD.mdlZD(2)*M.ZD(:,2);

AD.mdlNU =gmregress(M.NU(:,2),M.NU(:,1));
Mn.NU(:,2) = AD.mdlNU(1)+AD.mdlNU(2)*M.NU(:,2);
AD.mdlNW =gmregress(M.NW(:,2),M.NW(:,1));
Mn.NW(:,2) = AD.mdlNW(1)+AD.mdlNW(2)*M.NW(:,2);
AD.mdlWC =gmregress(M.WC(:,2),M.WC(:,1));
Mn.WC(:,2) = AD.mdlWC(1)+AD.mdlWC(2)*M.WC(:,2);
AD.mdlMLU =gmregress(M.MLU(:,2),M.MLU(:,1));
Mn.MLU(:,2) = AD.mdlMLU(1)+AD.mdlMLU(2)*M.MLU(:,2);
AD.mdlTTR =gmregress(M.TTR(:,2),M.TTR(:,1));
Mn.TTR(:,2) = AD.mdlTTR(1)+AD.mdlTTR(2)*M.TTR(:,2);

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



    