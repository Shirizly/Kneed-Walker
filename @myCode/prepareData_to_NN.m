function [obj] = prepareData_to_NN(obj)
% this function takes the results structure and extract the relevant data
% to matrix.

% need to have:
% 1) 'results' - sim results 
% 2) 'periods' - calculated periods from the sim
% 3) 'ids' - indecies of samples with real period (not 'Nan')
% 4) 'seqOrder' - the order in which the results.seq is organize.
%                 for example: 'tau','b',...
% 5) 'inputsNames' - cell array contain the names of the inputs
% 6) 'outputNames' - cell array contain the names of the outputs

period = obj.periods(obj.ids);
freq = 1./period;

seqMatrix = vertcat(obj.results(obj.ids).seq)'; % extracting the parameters from the structure to a matrix

tau = seqMatrix(strcmp('tau',obj.seqOrder),:);
b = seqMatrix(strcmp('b',obj.seqOrder),:);

% only for 4 neurons CPG:
c_1 = seqMatrix(strcmp('c_1',obj.seqOrder),:);
c_2 = seqMatrix(strcmp('c_2',obj.seqOrder),:);
c_3 = seqMatrix(strcmp('c_3',obj.seqOrder),:);
c_4 = seqMatrix(strcmp('c_4',obj.seqOrder),:);
w_12 = seqMatrix(strcmp('w_12',obj.seqOrder),:);
w_13 = seqMatrix(strcmp('w_13',obj.seqOrder),:);
w_14 = seqMatrix(strcmp('w_14',obj.seqOrder),:);
w_21 = seqMatrix(strcmp('w_21',obj.seqOrder),:);
w_23 = seqMatrix(strcmp('w_23',obj.seqOrder),:);
w_24 = seqMatrix(strcmp('w_24',obj.seqOrder),:);
w_31 = seqMatrix(strcmp('w_31',obj.seqOrder),:);
w_32 = seqMatrix(strcmp('w_32',obj.seqOrder),:);
w_34 = seqMatrix(strcmp('w_34',obj.seqOrder),:);
w_41 = seqMatrix(strcmp('w_41',obj.seqOrder),:);
w_42 = seqMatrix(strcmp('w_42',obj.seqOrder),:);
w_43 = seqMatrix(strcmp('w_43',obj.seqOrder),:);
sumW = sum([w_12;w_13;w_14;w_21;w_23;w_24;w_31;w_32;w_34;w_41;w_42;w_43],1);
prodW = (prod([w_12;w_13;w_14;w_21;w_23;w_24;w_31;w_32;w_34;w_41;w_42;w_43],1)).^(1/12);

% only for 2neurons symmetric CPG:
a = seqMatrix(strcmp('a',obj.seqOrder),:);
s = seqMatrix(strcmp('s',obj.seqOrder),:);

for k=1:2
    if k == 1 %define inputs
        tempNames = obj.inputsNames;
    else %define outputs
        tempNames = obj.outputNames;
    end
    
    for i=1:length(tempNames)
        switch tempNames{1,i}
            case 'tau'
                temp(i,:) = tau;
            case 'b'
                temp(i,:) = b;
            case 'a'
                temp(i,:) = a;         
            case 's'
                temp(i,:) = s;
            case 'c_1'
                temp(i,:) = c_1;
            case 'c_2'
                temp(i,:) = c_2;
            case 'c_3'
                temp(i,:) = c_3;
            case 'c_4'
                temp(i,:) = c_4;
            case 'w_{12}'
                temp(i,:) = w_12;
            case 'w_{13}'
                temp(i,:) = w_13;
            case 'w_{14}'
                temp(i,:) = w_14;
            case 'w_{21}'
                temp(i,:) = w_21;
            case 'w_{23}'
                temp(i,:) = w_23;
            case 'w_{24}'
                temp(i,:) = w_24;
            case 'w_{31}'
               temp(i,:) = w_31;
            case 'w_{32}'
                temp(i,:) = w_32;
            case 'w_{34}'
                temp(i,:) = w_34;
            case 'w_{41}'
                temp(i,:) = w_41;
            case 'w_{42}'
                temp(i,:) = w_42;
            case 'w_{43}'
                temp(i,:) = w_43;
            case 'prodW'
                temp(i,:) = prodW;
            case 'sumW'
                temp(i,:) = sumW;
            case 'period'
                temp(i,:) = Period;
            case 'freq'
                temp(i,:) = freq;
            case 'W123' % w12+w23+w31
                temp(i,:) = w_12+w_23+w_31;
            case 'W124' % w12+w24+w41
                temp(i,:) = w_12+w_24+w_41;
            case 'W132' % w13+w32+w21
                temp(i,:) = w_13+w_32+w_21;
            case 'W134' % w13+w34+w41
                temp(i,:) = w_13+w_34+w_41;
            case 'W142' % w14+w42+w21
                temp(i,:) = w_14+w_42+w_21;
            case 'W143' % w14+w43+w31
                temp(i,:) = w_14+w_43+w_31;
            case 'W234' % w23+w34+w42
                temp(i,:) = w_23+w_34+w_42;
            case 'W243' % w24+w43+w32
                temp(i,:) = w_24+w_43+w_32;
            otherwise
                warning('no such string');
       end
    end
    
    if k == 1 %define inputs
        obj.sampl = temp;
        clear temp
    else %define outputs
        obj.targ = temp;
    end
end

end

