function [ druglevel, time , name] = pharmacokineticsV2(infusions, weight, type, sesmins, makeFig, box, date)

% if nargin == 7
box = cellstr(box);
name = {['Box ' num2str(box{1}) ', ' datestr(date(1),'mmm-dd HH PM')]};
% else
%     name = [];
%% This fucntion calculates cocaine drug level (Molar Mass of Cocaine - 339.81g/MOLE - SigmaAldrich)
% Written By Kevin Coffey (Rutgers) & Olivia Kim (UPenn)
% INPUTS: infusions(ms_inf_onset,ms_inf_offset)
%         weight(body weight in Kg);
%         type();
%             (1) = IV - First Order (Eliminatoin Only; Root, 2011)
%             (2) = IV - Estimated Brain Level (2 compartmaent Model; Pan 1991; Roberts, 2013)
%             (3) = IV - Estimated Blood Level (2 compartmaent Model; Pan 1991)
%             (4) = IP - Estimated Brain Level (2 compartmaent Model; Pan 1991)
%             (5) = IP - Estimated Blood Level (2 compartmaent Model; Pan 1991)
%
%         sesmins(Length of Session in Minutes)
%         makeFig(1 make figure / 0 no figure)
%
% OUTPUT: Drug Level Duh!

%% %%%%%%%%%%%%%%% TYPE 1: First Order Calculation %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%  Output Concentration in mg/kg  %%%%%%%%%%%%%%%%%%%%%%%%
if type == 1;
    % Variables For the (Type 1) First Order Pharmacokinetics Equation
    %%%%(FILL THESE IN)
    clearvars -except makeFig infusions weight type druglevel
    bw = weight; %%%% Body Weight in Grams
    SESSIONLENGTH = sesmins; %%%% Session Length in Minutes
    cC = 1.2375; %%%% Enter cocaine concentration (mg/mL)
    F = (0.225/7.5); %%%% pump flow rate (mL/sec)
    % Constants and Calculations
    DOSE =((cC*F)/bw); % mg/kg per 1s of infusion
    HALFLIFE = 24; % Enther Half Life in Minutes
    K = log(2)/HALFLIFE; % Calculate Elimination Paramenter
    infusiontime=(infusions(:,1)/(1000)); % Infusion Start in 1s Units
    infusionend=(infusions(:,2)/(1000)); % Infusion End in 1s Units
    infusionduration=infusionend-infusiontime; % Infusion Duration in 1s Units
    infusioncheck=zeros(SESSIONLENGTH*60,2); % Logical Array Containing Infusion Logic
    timespan=(0:(SESSIONLENGTH*60)-1)'; % Time Array
    p=[];clear i;
    for i=1:length(infusiontime) % Calc Infusion Logical Array (Infusion or Not)
        if infusiontime(i)>=sesmins*60;
            continue %Ignore infusions after session end
        else
            % Calc Infusion Logical Array (Infusion or Not)
            p(end+1,1)=find((timespan(:,1)==floor(infusiontime(i))));
        end
    end
    infusioncheck(p)=1;
    for i=1:length(infusiontime)
        % Calc Infusion Dur (Infusion or Not)
        infusioncheck(floor(infusiontime(i,1))+1,2)=infusionduration(i,1);
    end
    druglevel=[0];
    for i=1:length(infusioncheck)-1
        druglevel(i+1,1)=(druglevel(i,1)+(DOSE*infusioncheck(i+1,2))*infusioncheck(i+1))*exp(-K/(60));
    end
    if makeFig==1
        figure;
        plot(druglevel);
    end
    clearvars -except makeFig infusions weight type druglevel name
end

%% %%%%%%%%%%%%%%% TYPE 2: Intravenus Estimated Brain Level %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%  Output Concentration in uMole/L or uM   %%%%%%%%%%%%%%
if type == 2;
    % Variables For the (Type 2) 2 Compartment - Estimated Brain Levels
    %%%%(FILL THESE IN)
    bw = weight; %%%% Body Weight in kGrams
    SESSIONLENGTH = sesmins; %%%% Session Length in Minutes
    cC = 1.2375; %%%% Enter cocaine concentration (mg/mL)
    F = (0.225/7.5); %%%% pump flow rate (mL/sec)
    % Constants and Calculations
    MGKGDOSE =((cC*F)/bw); %%%% mg/kg per 1s of infusion
    MGKGDOSE = .227;
    uMDOSE=MGKGDOSE/0.33981; %%%% Cocaine HCL (339.81g/MOLE or .33981mg/uMOLE)
    k12 = 0.233; % Pan & Justice 1990
    k21 = 0.212; % Pan & Justice 1990
    kel = 0.294; % Pan & Justice 1990
    ALPHA = 0.5*((k12 + k21 + kel)+sqrt((k12 + k21 + kel)^2-(4*k21*kel))); %%%% Represent the redistribution of Cocaine. Calculated using Pan et al. 1991 eqn. 0.06667 with Lau and Sun 2002 values for 0.5 mg/kg dose (see paper for justification)
    BETA = 0.5*((k12 + k21 + kel)-sqrt((k12 + k21 + kel)^2-(4*k21*kel))); %%%% Represent the Elimination of Cocaine. Calculated using Pan et al. 1991 eqn. 0.0193 here with Lau and Sun 2002 values for 0.5 mg/kg dose
    VOLUME = .15; %%%% Brain Apperant Volume of distribution in L per kg
    % K_FLOW = .233; %%%% Represents the flow between the two compartments
    infusiontime=(infusions(:,1)/(1000)); % Infusion Start in 1s Units
    infusionend=(infusions(:,2)/(1000)); % Infusion End in 1s Units
    infusiondur=infusionend-infusiontime; % Infusion Duration in 1s Units
    inf_dl=zeros(length(infusiondur),SESSIONLENGTH*60); % Pre allocate array
    % Calculate Drug Level for Each Infusion seperately
    for i = 1:length(infusiondur)
        for j = round(infusiontime(i,1))+1:(SESSIONLENGTH*60)
            inf_dl(i,j)=(((uMDOSE*infusiondur(i,1))*(k12))/(VOLUME*(ALPHA-BETA)))*(exp(-BETA*((j-round(infusiontime(i,1)))/60))-exp(-ALPHA*((j-round(infusiontime(i,1)))/60)));
        end
    end
    druglevel=sum(inf_dl); % Sum Individual Infusion Drug Levels
    if makeFig==1
        figure;
        plot(druglevel);
    end
    clearvars -except makeFig infusions weight type druglevel name
end

%% %%%%%%%%%%%%%%% TYPE 3: Estimated Blood Level %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%     Concentration in uMole/L or uM       %%%%%%%%%%%%%%
if type == 3;
    % Variables For the (Type 3) - Estimated Blood Levels Equation
    %%% FILL THESE IN
    bw = weight; %%%% Body Weight in kGrams
    SESSIONLENGTH = sesmins; %%%% Session Length in Minutes
    cC = 1.2375; %%%% Enter cocaine concentration (mg/mL)
    F = (0.225/7.5); %%%% pump flow rate (mL/sec)
    % Constants and Calculations
    MGKGDOSE =((cC*F)/bw); %%%% mg/kg per 1s of infusion
    uMDOSE=MGKGDOSE/0.33981; %%%% Cocaine HCL (339.81g/MOLE or .33981mg/uMOLE)
    k12 = 0.233; % Pan & Justice 1990
    k21 = 0.212; % Pan & Justice 1990
    kel = 0.294; % Pan & Justice 1990
    ALPHA = 0.5*((k12 + k21 + kel)+sqrt((k12 + k21 + kel)^2-(4*k21*kel))); %%%% Represent the redistribution of Cocaine. Calculated using Pan et al. 1991 eqn. 0.06667 with Lau and Sun 2002 values for 0.5 mg/kg dose (see paper for justification)
    BETA = 0.5*((k12 + k21 + kel)-sqrt((k12 + k21 + kel)^2-(4*k21*kel))); %%%% Represent the Elimination of Cocaine. Calculated using Pan et al. 1991 eqn. 0.0193 here with Lau and Sun 2002 values for 0.5 mg/kg dose
    VOLUME = .120; %%%% Apperant Volume of blood (Volume of Distrobution in L/kg). From Lau & Sun 2002
    % K_FLOW = .233; %%%% Represents the flow between the two compartments
    infusiontime=(infusions(:,1)/(1000)); % Infusion Start in 1s Units
    infusionend=(infusions(:,2)/(1000)); % Infusion End in 1s Units
    infusiondur=infusionend-infusiontime; % Infusion Duration in 1s Units
    inf_dl=zeros(length(infusiondur),SESSIONLENGTH*60); % Pre allocate array
    % Calculate Drug Level for Each Infusion seperately
    for i = 1:length(infusiondur)
        for j = round(infusiontime(i,1))+1:(SESSIONLENGTH*60)
            inf_dl(i,j)=(((uMDOSE*infusiondur(i,1)))/(VOLUME*(ALPHA-BETA)))*(((k12-BETA)*exp(-BETA*((j-round(infusiontime(i,1)))/60)))-((k12-ALPHA)*exp(-ALPHA*((j-round(infusiontime(i,1)))/60))));
        end
    end
    druglevel=sum(inf_dl); % Sum Individual Infusion Drug Levels
    if makeFig==1
        figure;
        plot(druglevel);
    end
    clearvars -except makeFig infusions weight type druglevel name
end

%% %%%%%%%%%%%%%%% TYPE 4: Intraparitoneal Estimated Brain Level %%%%%%%%%
%%%%%%%%%%%%%%%%%%     Concentration in uMole/L or uM       %%%%%%%%%%%%%%
if type == 4;
    % Variables For the (Type 4) 2 Compartment - IP Estimated Brain Levels
    %(FILL THESE IN)
    bw = weight; %%%% Body Weight in kGrams
    SESSIONLENGTH = sesmins; %%%% Session Length in Minutes
    MGKGDOSE =(15); %%%% mg/kg per infusion
    uMDOSE=MGKGDOSE/0.33981; %%%% Cocaine HCL (339.81g/MOLE or .33981mg/uMOLE)
    k12 = 0.233; % Pan & Justice 1990
    k21 = 0.212; % Pan & Justice 1990
    kel = 0.294; % Pan & Justice 1990
    ALPHA = 0.5*((k12 + k21 + kel)+sqrt((k12 + k21 + kel)^2-(4*k21*kel))); %%%% Represent the redistribution of Cocaine. Calculated using Pan et al. 1991 eqn. 0.06667 with Lau and Sun 2002 values for 0.5 mg/kg dose (see paper for justification)
    BETA = 0.5*((k12 + k21 + kel)-sqrt((k12 + k21 + kel)^2-(4*k21*kel))); %%%% Represent the Elimination of Cocaine. Calculated using Pan et al. 1991 eqn. 0.0193 here with Lau and Sun 2002 values for 0.5 mg/kg dose
    VOLUME = .15; %%%% Brain Apperant Volume of distribution in L per kg
    F=.8581; % Derived from 30mg/kg estimated parameter (F*88.28uMol/kg)/(Volime Distribution Blood l/kg)-(Pan & Justice 1990)
    kA= .0248; % Pan & Justice 1990
    % K_FLOW = .233; %%%% Represents the flow between the two compartments
    infusiontime=(infusions(:,1)/(1000)); % Infusion Start in 1s Units
    inf_dl=zeros(length(infusiontime),SESSIONLENGTH*60);% Pre allocate array
    % Calculate Drug Level for Each Infusion seperately
    for i = 1:length(infusiontime)
        for j = round(infusiontime(i,1))+1:(SESSIONLENGTH*60)
            inf_dl(i,j)=(F*uMDOSE*kA*k21/VOLUME)*...
                ( (exp(-ALPHA*((j-round(infusiontime(i,1)))/60)))/((kA-ALPHA)*(BETA-ALPHA)) ...
                + (exp(-BETA*((j-round(infusiontime(i,1)))/60)))/((kA-BETA)*(ALPHA-BETA)) ...
                + (exp(-kA*((j-round(infusiontime(i,1)))/60)))/((ALPHA-kA)*(BETA-kA)) );
        end
    end
    if length(inf_dl(:,1))>1
        druglevel=sum(inf_dl); % Sum Individual Infusion Drug Levels
    else
        druglevel=inf_dl;
    end
    if makeFig==1
        figure;
        plot(druglevel);
    end
    clearvars -except makeFig infusions weight type druglevel name
end

%% %%%%%%%%%%%%%%% TYPE 5: Intraparitoneal Estimated Blood Level %%%%%%%%
%%%%%%%%%%%%%%%%%%     Concentration in uMole/L or uM       %%%%%%%%%%%%%
if type == 5;
    % Variables For the (Type 5) 2 Compartment - IP Estimated Blood Levels
    %(FILL THESE IN)
    bw = weight; %%%% Body Weight in kGrams
    SESSIONLENGTH = sesmins; %%%% Session Length in Minutes
    MGKGDOSE =(15); %%%% mg/kg per infusion
    uMDOSE=MGKGDOSE/0.33981; %%%% Cocaine HCL (339.81g/MOLE or .33981mg/uMOLE)
    k12 = 0.233; % Pan & Justice 1990
    k21 = 0.212; % Pan & Justice 1990
    kel = 0.294; % Pan & Justice 1990
    ALPHA = 0.5*((k12 + k21 + kel)+sqrt((k12 + k21 + kel)^2-(4*k21*kel))); %%%% Represent the redistribution of Cocaine. Calculated using Pan et al. 1991 eqn. 0.06667 with Lau and Sun 2002 values for 0.5 mg/kg dose (see paper for justification)
    BETA = 0.5*((k12 + k21 + kel)-sqrt((k12 + k21 + kel)^2-(4*k21*kel))); %%%% Represent the Elimination of Cocaine. Calculated using Pan et al. 1991 eqn. 0.0193 here with Lau and Sun 2002 values for 0.5 mg/kg dose
    VOLUME = .12; %%%% Apperant Volume of blood (Volume of Distrobution in L/kg). From Lau & Sun 2002
    F=.3915; % Derived from 30mg/kg estimated parameter (F*88.28uMol/kg)/(Volime Distribution Blood l/kg)-(Pan & Justice 1990)
    kA= .0248; % Pan & Justice 1990
    % K_FLOW = .233; %%%% Represents the flow between the two compartments
    infusiontime=(infusions(:,1)/(1000)); % Infusion Start in 1s Units
    inf_dl=zeros(length(infusiontime),SESSIONLENGTH*60); % Pre allocate array
    % Calculate Drug Level for Each Infusion seperately
    for i = 1:length(infusiontime)
        for j = round(infusiontime(i,1))+1:(SESSIONLENGTH*60)
            inf_dl(i,j)=(F*uMDOSE*kA/VOLUME)*...
                ( (((k21-ALPHA)/((kA-ALPHA)*(BETA-ALPHA)))*exp(-ALPHA*((j-round(infusiontime(i,1)))/60))) ...
                + (((k21-BETA)/((kA-BETA)*(ALPHA-BETA)))*exp(-BETA*((j-round(infusiontime(i,1)))/60))) ...
                + (((k21-kA)/((ALPHA-kA)*(BETA-kA)))*exp(-kA*((j-round(infusiontime(i,1)))/60))) );
        end
    end
    if length(inf_dl(:,1))>1
        druglevel=sum(inf_dl); % Sum Individual Infusion Drug Levels
    else
        druglevel=inf_dl;
    end
    if makeFig==1
        figure;
        plot(druglevel);
    end
    clearvars -except makeFig infusions weight type druglevel name
end

time = {[1:length(druglevel)]./60};
druglevel = {druglevel};
end

