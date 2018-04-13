clc; clear; close all;

%-94dBm is antenna receiver sensitivity
%-84dBm is chosen to give room for unexpected noise sources!
acc_dBm = -84;            %Accepted received power

R = 1;                    %Measurement Shunt-Resistance
I_tx_max = 1*10.^(-3);    %Transmit current
I_tx_min = 4*10.^(-6);    %I_tx_max - 24dBm
Ptx_max = I_tx_max*R^(2); %Transmit Power
Ptx_min = I_tx_min*R^(2); %Transmit Power

% Antennasize = 2.7cm and freq = 2.4GHz
% https://www.everythingrf.com/rf-calculators/antenna-near-field-distance-calculator  
d0     = 0.01167;    %(meter) estimation of the Far Field distance for the TelosB antenna

N = 200; %meter from the base station "half of a racetrack width"
x = linspace(-N,N,N*2+1);  
y = linspace(-N,N,N*2+1);  
[X,Y] = meshgrid(x,y);
%% 0dBm = max power, -24dBm = min power, Runner running at 12km/h ? 1m/333ms
%  AIR = 2
gammaAIR = 2;
% Office = 5.5 (2% of the distance) for every 5m one wall of thickness 30cm exist! 
gammaOffice = (2*94+5.5*6)/100; %2.21

%BaseStation
d = sqrt(X.^(2)+Y.^(2));    %euclidean distance
d((N*2)/2+1,(N*2)/2+1) = 1; %to avoid inf number in the center!

PAir_W = Ptx_max.*((d0./d).^gammaAIR); %Watt
PAir   = 10*log10(PAir_W/0.001);       %dBm

%NorthSation
dNorth = sqrt((X-40).^(2)+Y.^(2)); %euclidean distance     
dNorth((N*2)/2+1,(N*2)/2+41) = 1;  %to avoid inf number in the center!  

PAirNorth_W = Ptx_max.*((d0./dNorth).^gammaAIR); %Watt
PAirNorth   = 10*log10(PAirNorth_W./0.001);      %dBm

%SouthStation
dSouth = sqrt((X+40).^(2)+Y.^(2));  %euclidean distance
dSouth((N*2)/2+1,(N*2)/2-39) = 1;   %to avoid inf number in the center!

PAirSouth_W = Ptx_max.*((d0./dSouth).^gammaAIR); %dBm
PAirSouth   = 10*log10(PAirSouth_W./0.001);      %Watt         
                         
%Combination of stations
PAIRCombined = 10*log10((PAir_W + PAirNorth_W + PAirSouth_W)./0.001); %dBm

%% Fading FF=Fast fading, SF= slow fading  
%Fast Fading 250ms fast fading effect
mu = 35+30; %+30 from dBW to dBm
sigma = 5;
X_ff = normrnd(mu,sigma,[length(x),length(y)]);
X_randff = rand(length(x),length(y)) < 0.1;
ff = -(X_randff.*X_ff);

%North
X_ff_north = normrnd(mu,sigma,[length(x),length(y)]);
X_randff_north = rand(length(x),length(y)) < 0.1;
ff_north = -(X_randff_north.*X_ff);

%South
X_ff_south = normrnd(mu,sigma,[length(x),length(y)]);
X_randff_south = rand(length(x),length(y)) < 0.1;
ff_south = -(X_randff_south.*X_ff);

%Slow Fading 10sec effect
X_sf = normrnd(mu,sigma,[length(x),length(y)]);
X_randsf = rand(length(x),length(y)) < 0.1;
X_Coor = find(X_randsf > 0.5);

for i=1:length(X_Coor)
   if X_Coor(i) < 22
      X_Coor(i) = 22;
   end
end

X_randsf(X_Coor-21:X_Coor+21)=1; %10sec slow fading effect
sf = -(X_randsf.*X_sf);

%NORTH
X_sf_north = normrnd(mu,sigma,[length(x),length(y)]);
X_randsf_north = rand(length(x),length(y)) < 0.1;
X_Coor_north = find(X_randsf_north > 0.5);

for i=1:length(X_Coor_north)
   if X_Coor_north(i) < 22
      X_Coor_north(i) = 22;
   end
end

X_sf_north(X_Coor_north-21:X_Coor_north+21)=1; %10sec slow fading effect
sf_north = -(X_sf_north.*X_sf_north);

%SOUTH
X_sf_south = normrnd(mu,sigma,[length(x),length(y)]);
X_randsf_south = rand(length(x),length(y)) < 0.1;
X_Coor_south = find(X_randsf_south > 0.5);

for i=1:length(X_Coor_south)
   if X_Coor_south(i) < 22
      X_Coor_south(i) = 22;
   end
end

X_sf_south(X_Coor_south-21:X_Coor_south+21)=1; %10sec slow fading effect
sf_south = -(X_sf_south.*X_sf_south);

PAir_f = PAir + sf + ff;
PAirNorth_f = PAirNorth + sf_north + ff_north;
PAirSouth_f = PAirSouth + sf_south + ff_south;
PAir_W_f      = 10.^(PAir_f./10);
PAirNorth_W_f = 10.^(PAirNorth_f./10);
PAirSouth_W_f = 10.^(PAirSouth_f./10);

PAIRCombined_sf = 10*log10((PAir_W_f + PAirNorth_W + PAirSouth_W)./0.001); %dBm
PAIRCombined_sf_All_Noisy = 10*log10((PAir_W_f + PAirNorth_W_f + PAirSouth_W_f)./0.001); %dBm

%% Plotting Signal Range in AIR for 0dBm
figure(1)
hold on
pcolor(x,y,PAir_f)
title({'LOGPATH RECEIVED SIGNAL PLOT';'BASE-Station, AIR, Trx = 0dBm. Slow and fast fading effects from BASE ONLY'})
xlabel('-200m < BaseStation < 200m')
ylabel('-200m < BaseStation < 200m')
shading interp;
set(gca, 'clim', [acc_dBm 0]);
colormap([0 0 0; jet]);
colorbar;

%Ellipse
a=N-2; % horizontal radius
b=N/5; % vertical radius
x0=0;  % x0,y0 ellipse centre coordinates
y0=0;
t=-pi:0.01:pi;
x_ellipse=x0+a*cos(t);
y_ellipse=y0+b*sin(t);
plot(x_ellipse,y_ellipse,'r')
legend('log10 distance path model', 'RaceTrack, "H=80m, L=400m"');
hold off

figure(2)
hold on
pcolor(x,y,PAIRCombined_sf)
title({'LOGPATH RECEIVED SIGNAL PLOT';'COMBINED-Stations, AIR, Trx = 0dBm. Slow and fast fading effects from BASE ONLY'})
xlabel('-200m < BaseStation < 200m') % x-axis label
ylabel('-200m < BaseStation < 200m') % y-axis label
shading interp;
set(gca, 'clim', [acc_dBm 0]);
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'r')
legend('log10 distance path model', 'RaceTrack, "H=80m, L=400m"');
hold off

figure(3)
hold on
pcolor(x,y,PAIRCombined_sf_All_Noisy)
title({'LOGPATH RECEIVED SIGNAL PLOT';'COMBINED-Stations, AIR, Trx = 0dBm. Slow and fast fading effects from ALL STATIONS'})
xlabel('-200m < BaseStation < 200m') % x-axis label
ylabel('-200m < BaseStation < 200m') % y-axis label
shading interp;
set(gca, 'clim', [acc_dBm 0]);
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'r')
legend('log10 distance path model', 'RaceTrack, "H=80m, L=400m"');
hold off

%% Plotting Deep Fading Binary plots
DF_PAIR = zeros(length(PAir_f)); %Deep Fade Power AIR
DFCoor1_PAIR = PAir_f>acc_dBm;
DFCoor2_PAIR = PAir_f<=acc_dBm;
DF_PAIR(DFCoor1_PAIR) = -9999;
DF_PAIR(DFCoor2_PAIR) = 0;

figure(4)
hold on
pcolor(x,y,DF_PAIR)
title({'BINARY DEEP FADING PLOT';'BASE-Station, AIR, Trx = 0dBm. Slow and fast fading effects from BASE ONLY'})
xlabel('-200m < BaseStation < 200m')
ylabel('-200m < BaseStation < 200m')
shading interp;
set(gca, 'clim', [-1 0]);
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'b')
legend('log10 distance path model', 'RaceTrack, "H=80m, L=400m"');
hold off

DF_PAIR_COMB = zeros(length(PAIRCombined_sf));
DFCoor1_PAIR_COMB = PAIRCombined_sf>acc_dBm;
DFCoor2_PAIR_COMB = PAIRCombined_sf<=acc_dBm;
DF_PAIR_COMB(DFCoor1_PAIR_COMB) = -9999;
DF_PAIR_COMB(DFCoor2_PAIR_COMB) = 0;

figure(5)
hold on
pcolor(x,y,DF_PAIR_COMB)
title({'BINARY DEEP FADING PLOT';'COMBINED-Stations, AIR, Trx = 0dBm. Slow and fast fading effects from BASE ONLY'})
xlabel('-200m < BaseStation < 200m')
ylabel('-200m < BaseStation < 200m')
shading interp;
set(gca, 'clim', [-1 0]);
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'b')
legend('log10 distance path model', 'RaceTrack, "H=80m, L=400m"');
hold off

DF_PAIR_COMB_noisy = zeros(length(PAIRCombined_sf_All_Noisy));
DFCoor1_PAIR_COMB_Noisy = PAIRCombined_sf_All_Noisy>acc_dBm;
DFCoor2_PAIR_COMB_Noisy = PAIRCombined_sf_All_Noisy<=acc_dBm;
DF_PAIR_COMB_noisy(DFCoor1_PAIR_COMB_Noisy) = -9999;
DF_PAIR_COMB(DFCoor2_PAIR_COMB_Noisy) = 0;

figure(6)
hold on
pcolor(x,y,DF_PAIR_COMB_noisy)
title({'BINARY DEEP FADING PLOT';'COMBINED-Stations, AIR, Trx = 0dBm. Slow and fast fading effects from ALL STATIONS'})
xlabel('-200m < BaseStation < 200m')
ylabel('-200m < BaseStation < 200m')
shading interp;
set(gca, 'clim', [-1 0]);
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'b')
legend('log10 distance path model', 'RaceTrack, "H=80m, L=400m"');
hold off
