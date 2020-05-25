function [Mn] = Kpredict(M,AD)
Mn=M;

Mn.FI = AD.mdlFI(1)+AD.mdlFI(2)*M.FI;
Mn.ND = AD.mdlND(1)+AD.mdlND(2)*M.ND;
Mn.SD = AD.mdlSD(1)+AD.mdlSD(2)*M.SD;
Mn.ZD = AD.mdlZD(1)+AD.mdlZD(2)*M.ZD;
Mn.NU = AD.mdlNU(1)+AD.mdlNU(2)*M.NU;
Mn.NW = AD.mdlNW(1)+AD.mdlNW(2)*M.NW;
Mn.WC = AD.mdlWC(1)+AD.mdlWC(2)*M.WC;
Mn.ML = AD.mdlMLU(1)+AD.mdlMLU(2)*M.ML;
Mn.TR = AD.mdlTTR(1)+AD.mdlTTR(2)*M.TR;
