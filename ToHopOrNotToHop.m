clc; clear; close all;

R = 1;                    %Measurement Shunt-Resistance
I_tx_max = 1*10.^(-3);    %Transmit current
I_tx_min = 4*10.^(-6);    %I_tx_max - 24dBm
Ptx_max = I_tx_max*R^(2); %Transmit Power
Ptx_min = I_tx_min*R^(2); %Transmit Power

% Antennasize = 2.7cm and freq = 2.4GHz
% https://www.everythingrf.com/rf-calculators/antenna-near-field-distance-calculator  
d0     = 0.01167;    %(meter) estimation of the Far Field distance for the TelosB antenna

N = 200; %meter from the base station "half of a racetrack width"
x = linspace(-N,N,N*4+1);  
y = linspace(-N,N,N*4+1);  
[X,Y] = meshgrid(x,y);
%% 0dBm = max power, -24dBm = min power
%  AIR = 2
gammaAIR = 2;
% Office = 5.5 (2% of the distance) for every 5m one wall of thickness 30cm exist! 
gammaOffice = (2*94+5.5*6)/100; %2.21

%BaseStation
d = sqrt(X.^(2)+Y.^(2)); %euclidean distance
d(N/2+1,N/2+1) = 1;      %to avoid inf number in the center!

PAir_W     = Ptx_max.*((d0./d).^gammaAIR); %Watt
PAir       = 10*log10(PAir_W/0.001);    %dBm

%NorthSation
dNorth = sqrt((X-50).^(2)+Y.^(2));       %euclidean distance
dNorth(N/2+1,N/2+26) = 1;                %to avoid inf number in the center!

PAirNorth_W = Ptx_max.*((d0./dNorth).^gammaAIR);                           %Watt
PAirNorth   = 10*log10(PAirNorth_W./0.001);          %dBm

%SouthStation
dSouth = sqrt((X+50).^(2)+Y.^(2));       %euclidean distance
dSouth(N/2+1,N/2-24) = 1;                %to avoid inf number in the center!

PAirSouth_W = Ptx_max.*((d0./dSouth).^gammaAIR);  
PAirSouth   = 10*log10(PAirSouth_W./0.001);          %dBm
                         %Watt

%Combination of stations
PAIRCombined = 10*log10((PAir_W + PAirNorth_W + PAirSouth_W)./0.001);          %dBm

%% Fading FF=Fast fading, SF= slow fading  

a=148; % horizontal radius
b=20; % vertical radius
x0=0; % x0,y0 ellipse centre coordinates
y0=0;
t=-pi:0.01:pi;
x_ellipse=x0+a*cos(t);
y_ellipse=y0+b*sin(t);
mu = 35+30; %+30 from dBW to dBm
sigma = 5;

%Fast Fading 350ms fast fading effect
X_ff = normrnd(mu,sigma,[length(x),length(y)]);
X_randff = rand(length(x),length(y)) < 0.1;
ff = -(X_randff.*X_ff);

%Slow Fading
X_sf = normrnd(mu,sigma,[length(x),length(y)]);
X_randsf = rand(length(x),length(y)) < 0.1;
X_Coor = find(X_randsf > 0.5);

for i=1:length(X_Coor)
   if X_Coor(i) < 13
      X_Coor(i) = 13;
   end
end
X_randsf(X_Coor-12:X_Coor+12)=1; %10sec slow fading effect
sf = -(X_randsf.*X_sf);

PAir_sf = PAir + sf + ff;
PAirNorth_sf = PAirNorth + sf;
PAirSouth_sf = PAirSouth + sf;
PAir_W_sf      = 10.^(PAir_sf./10);
PAirNorth_W_sf = 10.^(PAirNorth_sf./10);
PAirSouth_W_sf = 10.^(PAirSouth_sf./10);
PAIRCombined_sf = 10*log10((PAir_W_sf + PAirNorth_W_sf + PAirSouth_W_sf)./0.001); %dBm

%% Plotting Signal Range in AIR for 0dBm
figure(1)
hold on
pcolor(x,y,PAir_sf)
title('0dBm transmit power decay in AIR. BaseStation')
xlabel('-150m < BaseStation < 150m') % x-axis label
ylabel('-150m < BaseStation < 150m') % y-axis label
shading interp;
set(gca, 'clim', [-94 0]); %-94dBm is antenna receiver sensitivity
colormap([0 0 0; jet]);
colorbar;

%Ellipse
a=148; % horizontal radius
b=20; % vertical radius
x0=0; % x0,y0 ellipse centre coordinates
y0=0;
t=-pi:0.01:pi;
x_ellipse=x0+a*cos(t);
y_ellipse=y0+b*sin(t);
plot(x_ellipse,y_ellipse,'r')
hold off

figure(2)
hold on
pcolor(x,y,PAIRCombined_sf)
title('0dBm transmit power decay in AIR. Combined Stations')
xlabel('-150m < BaseStation < 150m') % x-axis label
ylabel('-150m < BaseStation < 150m') % y-axis label
shading interp;
set(gca, 'clim', [-94 0]); %-94dBm is antenna receiver sensitivity
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'r')
legend('Log-Distance path model', 'RaceTrack');
hold off

DF_PAIR = zeros(length(PAir_sf));
DFCoor1_PAIR = find(PAir_sf>-94);
DFCoor2_PAIR = find(PAir_sf<=-94);
DF_PAIR(DFCoor1_PAIR) = -9999;
DF_PAIR(DFCoor2_PAIR) = 0;

figure(3)
hold on
pcolor(x,y,DF_PAIR)
title('0dBm transmit power decay in AIR. Combined Stations')
xlabel('-150m < BaseStation < 150m') % x-axis label
ylabel('-150m < BaseStation < 150m') % y-axis label
shading interp;
set(gca, 'clim', [-1 0]); %-94dBm is antenna receiver sensitivity
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'r')
legend('Log-Distance path model', 'RaceTrack');
hold off

DF_PAIR_COMB = zeros(length(PAIRCombined_sf));
DFCoor1_PAIR_COMB = find(PAIRCombined_sf>-94);
DFCoor2_PAIR_COMB = find(PAIRCombined_sf<=-94);
DF_PAIR_COMB(DFCoor1_PAIR_COMB) = -9999;
DF_PAIR_COMB(DFCoor2_PAIR_COMB) = 0;

figure(4)
hold on
pcolor(x,y,DF_PAIR_COMB)
title('0dBm transmit power decay in AIR. Combined Stations')
xlabel('-150m < BaseStation < 150m') % x-axis label
ylabel('-150m < BaseStation < 150m') % y-axis label
shading interp;
set(gca, 'clim', [-1 0]); %-94dBm is antenna receiver sensitivity
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'r')
legend('Log-Distance path model', 'RaceTrack');
hold off
