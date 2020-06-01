function ampSpec = fft2ampSpec(Y, N, N_fastest)
% Code taken from mySpectrum_V2 by Dr. Tsevi Beatus, HUJI course 78852.

P2 = abs(Y/N);  % calc amplitude of entire Y and normalize by 1/N
ampSpec = P2(1:N_fastest); % take the n>=0 half of the spectrum

d = mod(N,2)==1 ;
ampSpec(2:end-d) = 2*ampSpec(2:end-d);
% explanation for the above two lines:
% multiply by 2 only those modes that appear twice in fft
% either way, do not x2 the first term. 
% the last term depends whether N is odd/even
% the next two lines can handle both odd and even N 
% if N is ODD we get d=1, then we do not x2 last term
% if N is EVEN we get d=0, then we x2 all terms


end