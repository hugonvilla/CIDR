function [RI] = RIMeasures(Hac,Hpc,fv)
Hac(isnan(Hac)) = 0; 
Hpc(isnan(Hpc)) = 0;
Nch = size(Hpc,2);
for i = 1:Nch
    %%% Peers
    clear tvi 
    Hp = Hpc(:,i); %predicted index
    if nnz(Hp) > 0
        tvi(:,1) = [nonzeros(Hp(1)); find(diff(Hp)==1)+1]; %intial times indices
        tvi(:,2) = [find(diff(Hp)==-1);nonzeros(Hp(end))*numel(Hp)]  ; %final time indices
        THp=(tvi-1)./fv; %time table in seconds
        FHp(i) = size(THp,1); %number of interactions
        DHp = THp(:,2)-THp(:,1); %duraction vector
        MDHp(i) = mean(DHp); %mean duration
        NDHp(i) = median(DHp); %median duration
        SDDHp(i) = std(DHp); %standard deviation of duration
        ZDHp(i) = sum(DHp); %sum
    else
        FHp(i) = 0; MDHp(i)=0; NDHp(i)=0; SDDHp(i)=0; ZDHp(i)=0;
    end
    
    %%% Adults    
    clear tvi
    Ha = Hac(:,i); %predicted index
    if nnz(Ha) > 0
        tvi(:,1) = [nonzeros(Ha(1)); find(diff(Ha)==1)+1]; %intial times indices
        tvi(:,2) = [find(diff(Ha)==-1);nonzeros(Ha(end))*numel(Ha)]; %final time indices
        THa=(tvi-1)./fv; %time table in seconds
        FHa(i) = size(THa,1); %number of interactions
        DHa = THa(:,2)-THa(:,1); %duraction vector
        MDHa(i) = mean(DHa); %mean duration
        NDHa(i) = median(DHa); %median duration
        SDDHa(i) = std(DHa); %standard deviation of duration
        ZDHa(i) = sum(DHa);
    else
        FHa(i)=0; MDHa(i)=0;NDHa(i)=0; SDDHa(i)=0; ZDHa(i)=0;
    end
    
end

    RI.FI=[FHa' FHp'];
    RI.MD = [MDHa' MDHp'];
    RI.ND = [NDHa' NDHp'];
    RI.SD = [SDDHa' SDDHp'];
    RI.ZD = [ZDHa' ZDHp'];
