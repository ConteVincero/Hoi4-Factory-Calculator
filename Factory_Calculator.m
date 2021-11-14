clear
global Civ_Cost
global MConv_Cost
global Mil_Cost
global Civ_Output
global Avg_Inf
global Trade_Bonus
global Civ_Bonus
global Mil_Bonus
global Conv_Bonus

End_Date = datenum("1-1-1940",'dd-mm-yyyy');

%for End_Date = datenum("1-1-1939",'dd-mm-yyyy'):10:datenum("1-1-1942",'dd-mm-yyyy')
    Civ_Cost = 10800;
    MConv_Cost = 9000;
    Mil_Cost = 7200;
    Civ_Output = 5;
    Avg_Inf = 1.7;
    Trade_Bonus = 0.1;
    Civ_Bonus = -0.3;
    Mil_Bonus = -0.3;
    Conv_Bonus = -0.3;

    Start_Date = datenum("1-1-1936",'dd-mm-yyyy');
    Mil_Max = 0;
    Best_Mil_Date = 0;
    Mil_Chart = 0;
    Civ_Chart = 0;
    Mil_Sweep = uint16(zeros(1,End_Date-Start_Date));
    Best_Count = 0;
    Stop_Max = 0;

    for Mil_Date = Start_Date:End_Date
        %fprintf('%.4f \n',((Mil_Date-Start_Date)/(End_Date-Start_Date)*100))
        %Calculate the ammount of mils
        Max_Date = Mil_Date;
        Min_Date = Start_Date;
        [Min_Mils,~,~] = CalculateMils(Start_Date, End_Date, Mil_Date, Min_Date);
        [Max_Mils,~, ~] = CalculateMils(Start_Date, End_Date,Mil_Date, Max_Date);
        flag = false;
        while Max_Date - Min_Date > 1 || flag == false
            Mid_Date = (Max_Date+Min_Date)/2;
            [Mid_Mils,Mil_Total, Civ_Total] = CalculateMils(Start_Date, End_Date, Mil_Date, Mid_Date); 
            if Max_Mils > Min_Mils
                Min_Mils = Mid_Mils;
                Min_Date = Mid_Date;
            else
                Max_Mils = Mid_Mils;
                Max_Date = Mid_Date;
            end
            flag = true;
        end
        if Mid_Mils > Mil_Max 
            Mil_Max = Mid_Mils;
            Best_Mil_Date = Mil_Date;
            Best_Conv_Date = Mid_Date;
            Mil_Chart = Mil_Total;
            Civ_Chart = Civ_Total;
            if Best_Count > Stop_Max
                Stop_Max = Best_Count;
            end
            Best_Count = 0;
        else
            Best_Count = Best_Count + 1;
        end 
        Mil_Sweep(Mil_Date-Start_Date+1) = Mid_Mils;  
        if Best_Count > 1000
            break
        end
    end
    %X = datetime(End_Date,'Format','dd/MMMM/yyyy','ConvertFrom','datenum');
    %Y = Max_Mils;
    %fprintf('%s \t %s \t %s \t %i \n' ,datetime(End_Date,'Format','dd/MMMM/yyyy','ConvertFrom','datenum'),datetime(Best_Conv_Date,'Format','dd/MMMM/yyyy','ConvertFrom','datenum'), datetime(Best_Mil_Date,'Format','dd/MMMM/yyyy','ConvertFrom','datenum'),Mil_Max);
    fprintf('Best date to stop converting Mils is: %s \n' , datetime(Best_Conv_Date,'Format','dd/MMMM/yyyy','ConvertFrom','datenum'));
    fprintf('Best date to start building Mils is: %s \n' , datetime(Best_Mil_Date,'Format','dd/MMMM/yyyy','ConvertFrom','datenum'));
    XVal = datetime((1:(length(Mil_Chart)))+Start_Date,'Format','dd/MM/yyyy','ConvertFrom','datenum');
    plot(XVal,Mil_Chart)
    hold on 
    plot(XVal,Civ_Chart)
    XVal = datetime((1:(length(Mil_Sweep)))+Start_Date,'Format','dd/MM/yyyy','ConvertFrom','datenum');
    plot(XVal,Mil_Sweep)
    hold off
    legend('Military Factories','Civilian Factories','Mils by changeover date')
    xlabel('Changeover Date')
    ylabel('Factories')
    beep
%end

function [Progress,Built] = Calc_Build(Progress, Cost, State)
    global Civ_Flag
    Built = 0;
    if Progress > Cost
        Progress = Progress - Cost;
        Built = 1;
        if State < 2 
            Civ_Flag = true;
        end
    end
end

function [Mils, Mil_Total, Civ_Total] = CalculateMils(Start_Date, End_Date, Mil_Date, MConv_Date)
    global Civ_Flag
    global Civ_Cost
    global MConv_Cost
    global Mil_Cost
    global Civ_Output
    global Avg_Inf
    global Trade_Bonus
    global Civ_Bonus
    global Mil_Bonus
    global Conv_Bonus
    
    Civ_Total = uint16(zeros(1,End_Date-Start_Date));
    Mil_Total = Civ_Total;
    Mils = 36;
    Civs = 47;
    Civ_Blocks = zeros(1,60);
    State(1:60) = 0;                %0 = convert mils , 1 = build civs, 2 = build mils
    Civ_Flag = true;
    Progress = zeros(1,60);
    P_Slots = 0;

    for Cur_Date = Start_Date:End_Date
        %Assign blocks of 15 civilian factories
        if Civ_Flag == true
            Max_Slots = fix(Civs/15);
            Civ_Blocks(1:Max_Slots) = 15;
            if rem(Civs,15) >0
                Max_Slots = Max_Slots +1;
                Civ_Blocks(Max_Slots) = rem(Civs,15);
            end
            if Max_Slots > P_Slots                  %If a new slot has opened
                if Cur_Date < MConv_Date
                    if Mils >0
                        State(Max_Slots) = 0;
                        Mils = Mils -1;
                    else
                        State(Max_Slots) = 1;
                    end
                else
                    if Cur_Date < Mil_Date
                        State(Max_Slots) = 1;
                    else
                        State(Max_Slots) = 2;
                    end
                end
            end
            P_Slots = Max_Slots;
        end

        %Calculate the construction progress
        Civ_Flag = false;
        %Progress = Progress + Civ_Blocks * Civ_Output * Civ_Bonus * Avg_Inf;    
        for i = 1:Max_Slots
            switch State(i)
                case 0
                    Progress(i) = Progress(i) + Civ_Blocks(i) * Civ_Output * (1 + Trade_Bonus + Conv_Bonus) * Avg_Inf;
                    [Progress(i), Built] = Calc_Build(Progress(i), MConv_Cost, State(i));                        
                    if Built >0 
                        Civs = Civs + Built;
                        %Check to see if you can build the factory
                        if Mils >0
                            %Check the date
                            if Cur_Date >= MConv_Date
                                State(i) = 1;
                            else                                    
                                Mils = Mils -1;
                            end
                        else
                            State(i) = 1;
                        end
                    end
                case 1
                    Progress(i) = Progress(i) + Civ_Blocks(i) * Civ_Output * (1 + Trade_Bonus + Civ_Bonus) * Avg_Inf;
                    [Progress(i), Built] = Calc_Build(Progress(i), Civ_Cost, State(i));  
                    if Built >0
                        Civs = Civs + Built;
                        if Cur_Date >= Mil_Date
                            State(i) = 2;
                        end
                    end
                case 2
                    Progress(i) = Progress(i) + Civ_Blocks(i) * Civ_Output * (1 + Trade_Bonus + Mil_Bonus) * Avg_Inf;
                    [Progress(i), Built] = Calc_Build(Progress(i), Mil_Cost, State(i));  
                    Mils = Mils + Built;
                if Civ_Flag == true
                    else
                end
            end
        end
        %Change depending on dates
        switch Cur_Date-Start_Date
            case 70
                Civs = Civs + 25;
                Conv_Bonus = 0.2;
                Civ_Bonus = 0;
                Mil_Bonus = 0.2;
            case 140
                Civs = Civs + 4;
            case 146
                Civ_Bonus = 0.1;
            case 159
                Civ_Bonus = 0.2;
                Mil_Bonus = 0.3;
                Conv_Bonus = 0.3; 
            case 210
                Trade_Bonus = 0.15;
            case 372
                Civ_Bonus = 0.3; 
                Mil_Bonus = 0.4;
                Conv_Bonus = 0.4;                
        end
        Civ_Total(Cur_Date - Start_Date+1) = Civs;
        Mil_Total(Cur_Date - Start_Date+1) = Mils;
%         XVal = datetime((1:(length(Civ_Total)))+Start_Date,'Format','dd/MM/yyyy','ConvertFrom','datenum');
%         plot(XVal,Civ_Total)
%         hold off
%         plot(XVal,Mil_Total)
    end
end