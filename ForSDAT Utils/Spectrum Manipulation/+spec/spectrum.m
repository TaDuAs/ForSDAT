function [ampSpec, f_half, f, Y] = spectrum(x, Fs) 
%
% Code taken from mySpectrum_V2.m by Dr Tsevi Beatu, HUJI course 78852 with
% some modifications by TADA
%
% Calculate the Fourier amplitude spectrum of the signal x
%
% inputs
%   x           - a signal (assumed to consist of real numbers)
%   Fs          - sampling frequency of x
%
% outputs
%   ampSpec - the ampliude spectrum of x
%   f_half  - the frequency vector corresponding to ampSpec
%   Y       - the result of fft(X)
%
% Tsevi Beatus, HUJI Course no. 78852.
%

N      = length(x) ;
modes  = 0:N-1 ;
% find number of the highest mode (account for odd/even N)
% N_fastest = ceil((N+1)/2) ;  
N_fastest = spec.findNFastest(N);

% set mode number of negative modes (account for odd/even N)
modes(N_fastest+1 : end) = modes(N_fastest+1 : end) - N ;
f = modes * Fs / N ;  % full frequency vector

% frequencies corresponding to spectrum (i.e. to modes with n>=0)
f_half = f(1:N_fastest) ; 

Y = fft(x); % at last, perform the Fourier Transform

ampSpec = spec.fft2ampSpec(Y, N, N_fastest);
end