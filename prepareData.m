function [ inputs,targ ] = prepareData( results,periods,ids,NNinput,NNtarget )
% this function takes the results and periods and prepare data data for NN

% inputs: 
% 1) results - the results structure as saved from jonathan's code.
% 2) periods - the period vector as saved from jonathan's code.
% 3) ids - ids of the genes that we want to work with.
% 4) NNinput - the NN inputs variables
% 5) NNtarget - the NN target.

% outputs:
% inputs - the input to the NN
% targ - the NN targets
%


MatsuokaParam = vertcat(results(ids).seq)'; % extracting the parameters from the structure to a matrix
MatsuokaParam = MatsuokaParam(1:18,:); % get rid of the the unimportant 'gen' (the k's for the control).

tau = MatsuokaParam(1,:);
b = MatsuokaParam(2,:);
c_i = MatsuokaParam(3:6,:);

W_ij = MatsuokaParam(7:18,:);
prod_W = (prod(W_ij,1)).^(1/12); % gemometric mean of weights
sum_W = sum(W_ij,1);            % sum of all weights

Period = periods(ids);
freq = 1./periods(ids);

%% making the NNinputs:
for i=1:length(NNinput)
   switch NNinput{1,i};
       case 'tau'
           inputs(i,:) = tau;
       case 'b'
           inputs(i,:) = b;
       case 'c_1'
           inputs(i,:) = c_i(1,:);
       case 'c_2'
           inputs(i,:) = c_i(2,:);
       case 'c_3'
           inputs(i,:) = c_i(3,:);
       case 'c_4'
           inputs(i,:) = c_i(4,:);
       case 'w_{12}'
           inputs(i,:) = W_ij(1,:);
       case 'w_{13}'
           inputs(i,:) = W_ij(2,:);
       case 'w_{14}'
           inputs(i,:) = W_ij(3,:);
       case 'w_{21}'
           inputs(i,:) = W_ij(4,:);
       case 'w_{23}'
           inputs(i,:) = W_ij(5,:);
       case 'w_{24}'
           inputs(i,:) = W_ij(6,:);
       case 'w_{31}'
           inputs(i,:) = W_ij(7,:);
       case 'w_{32}'
           inputs(i,:) = W_ij(8,:);
       case 'w_{34}'
           inputs(i,:) = W_ij(9,:);
       case 'w_{41}'
           inputs(i,:) = W_ij(10,:);
       case 'w_{42}'
           inputs(i,:) = W_ij(11,:);
       case 'w_{43}'
           inputs(i,:) = W_ij(12,:);
       case 'prodW'
           inputs(i,:) = prod_W;
       case 'sumW'
           inputs(i,:) = sum_W;
       case 'period'
           inputs(i,:) = Period;
       case 'freq'
           inputs(i,:) = freq;     
       otherwise
           warning('no such string');
   end
end

%% making the NNtarget:
for i=1:length(NNtarget)
   switch NNtarget{1,i};
       case 'tau'
           targ(i,:) = tau;
       case 'b'
           targ(i,:) = b;
       case 'c_1'
           targ(i,:) = c_i(1,:);
       case 'c_2'
           targ(i,:) = c_i(2,:);
       case 'c_3'
           targ(i,:) = c_i(3,:);
       case 'c_4'
           targ(i,:) = c_i(4,:);
       case 'w_{12}'
           targ(i,:) = W_ij(1,:);
       case 'w_{13}'
           targ(i,:) = W_ij(2,:);
       case 'w_{14}'
           targ(i,:) = W_ij(3,:);
       case 'w_{21}'
           targ(i,:) = W_ij(4,:);
       case 'w_{23}'
           targ(i,:) = W_ij(5,:);
       case 'w_{24}'
           targ(i,:) = W_ij(6,:);
       case 'w_{31}'
           targ(i,:) = W_ij(7,:);
       case 'w_{32}'
           targ(i,:) = W_ij(8,:);
       case 'w_{34}'
           targ(i,:) = W_ij(9,:);
       case 'w_{41}'
           targ(i,:) = W_ij(10,:);
       case 'w_{42}'
           targ(i,:) = W_ij(11,:);
       case 'w_{43}'
           targ(i,:) = W_ij(12,:);
       case 'prodW'
           targ(i,:) = prod_W;
       case 'sumW'
           targ(i,:) = sum_W;
       case 'period'
           targ(i,:) = Period;
       case 'freq'
           targ(i,:) = freq;
       otherwise
           warning('no such string');
   end
end

end

