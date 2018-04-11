clc; clear; close all;

R = 1;                    %Measurement Shunt-Resistance

I_tx_max = 1*10.^(-3);    %Transmit current
I_tx_min = 4*10.^(-6);    %I_tx_max - 24dBm

Ptx_max = I_tx_max*R^(2); %Transmit Power
Ptx_min = I_tx_min*R^(2); %Transmit Power

% Antennasize = 2.7cm and freq = 2.4GHz
% https://www.everythingrf.com/rf-calculators/antenna-near-field-distance-calculator  
d0     = 0.01167;    %(meter) estimation of the Far Field distance for the TelosB antenna
f      = 2.4*10^(9); %2.4GHz
c      = 3*10^(8);   %Speed of light
lambda = c/f;        %Wavelength of 2.4GHz
area   = (4*pi)^(2); %Isotropic lossless antenna
L      = 1;          %Lossless electronics assumption
Gt     = 100;        %Calculated based on the 100m free space range from the Telos_B datasheet!
Gr     = Gt;         %Same antenna

Prcvd_max = (Ptx_max*Gt*Gr*lambda^(2))/(area*d0^(2)*L); %Recieved signal power at   0dBm Ptx
Prcvd_min = (Ptx_min*Gt*Gr*lambda^(2))/(area*d0^(2)*L); %Recieved signal power at -24dBm Ptx

N = 150; %meter from the base station "half of a racetrack width"
x = linspace(-N,N,N+1);  
y = linspace(-N,N,N+1);  
[X,Y] = meshgrid(x,y);
%% 0dBm = max power, -24dBm = min power
%  AIR = 2
gammaAIR = 2;
% Office = 5.5 (2% of the distance) for every 5m one wall of thickness 30cm exist! 
gammaOffice = (2*94+5.5*6)/100; %2.21

%BaseStation
d = sqrt(X.^(2)+Y.^(2)); %euclidean distance
d(N/2+1,N/2+1) = 1;      %to avoid inf number in the center!

ZAir       = 10*log((Prcvd_max.*((d0./d).^gammaAIR)./0.001));    %dBm
ZAir_W     = Prcvd_max.*((d0./d).^gammaAIR);                     %Watt
ZAir_min   = 10*log((Prcvd_min.*((d0./d).^gammaAIR)./0.001));    %dBm
ZAir_W_min = Prcvd_min.*((d0./d).^gammaAIR);                     %Watt
ZOffice    = 10*log((Prcvd_max.*((d0./d).^gammaOffice)./0.001)); %dBm
ZOffice_W  = Prcvd_max.*((d0./d).^gammaOffice);                  %Watt

%NorthSation
dNorth = sqrt((X-50).^(2)+Y.^(2));       %euclidean distance
dNorth(N/2+1,N/2+26) = 1;                %to avoid inf number in the center!
dNorthmin = sqrt((X-4).^(2)+Y.^(2));     %euclidean distance
dNorthmin(N/2+1,N/2+3) = 1;              %to avoid inf number in the center!
dNorthOffice = sqrt((X-24).^(2)+Y.^(2)); %euclidean distance
dNorthOffice(N/2+1,N/2+13) = 1;          %to avoid inf number in the center!

ZAirNorth       = 10*log((Prcvd_max.*((d0./dNorth).^gammaAIR)./0.001));          %dBm
ZAirNorth_W     = Prcvd_max.*((d0./dNorth).^gammaAIR);                           %Watt
ZAirNorth_min   = 10*log((Prcvd_min.*((d0./dNorthmin).^gammaAIR)./0.001));       %dBm
ZAirNorth_W_min = Prcvd_min.*((d0./dNorthmin).^gammaAIR);                        %Watt
ZOfficeNorth    = 10*log((Prcvd_max.*((d0./dNorthOffice).^gammaOffice)./0.001)); %dBm
ZOfficeNorth_W  = Prcvd_max.*((d0./dNorthOffice).^gammaOffice);                  %Watt

%SouthStation
dSouth = sqrt((X+50).^(2)+Y.^(2));       %euclidean distance
dSouth(N/2+1,N/2-24) = 1;                %to avoid inf number in the center!
dSouthmin = sqrt((X+4).^(2)+Y.^(2));     %euclidean distance
dSouthmin(N/2+1,N/2-1) = 1;              %to avoid inf number in the center!
dSouthOffice = sqrt((X+24).^(2)+Y.^(2)); %euclidean distance
dSouthOffice(N/2+1,N/2-11) = 1;          %to avoid inf number in the center!

ZAirSouth       = 10*log((Prcvd_max.*((d0./dSouth).^gammaAIR)./0.001));          %dBm
ZAirSouth_W     = Prcvd_max.*((d0./dSouth).^gammaAIR);                           %Watt
ZAirSouth_min   = 10*log((Prcvd_min.*((d0./dSouthmin).^gammaAIR)./0.001));       %dBm
ZAirSouth_W_min = Prcvd_min.*((d0./dSouthmin).^gammaAIR);                        %Watt
ZOfficeSouth    = 10*log((Prcvd_max.*((d0./dSouthOffice).^gammaOffice)./0.001)); %dBm
ZOfficeSouth_W  = Prcvd_max.*((d0./dSouthOffice).^gammaOffice);                  %Watt

%Combination of stations
ZAIRCombined     = 10*log((ZAir_W + ZAirNorth_W + ZAirSouth_W)./0.001);             %dBm
ZAIRCombined_min = 10*log((ZAir_W_min + ZAirNorth_W_min + ZAirSouth_W_min)./0.001); %dBm
ZOfficeCombined  = 10*log((ZOffice_W + ZOfficeNorth_W + ZOfficeSouth_W)./0.001);    %dBm

%% Plotting Signal Range in AIR for 0dBm
figure(1)
hold on
pcolor(x,y,ZAir)
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
subplot(3,1,1)
pcolor(x,y,ZAirSouth)
title('0dBm transmit power decay in AIR. SouthStation')
xlabel('-150m < BaseStation < 150m') % x-axis label
ylabel('-150m < BaseStation < 150m') % y-axis label
shading interp;
set(gca, 'clim', [-94 0]); %-94dBm is antenna receiver sensitivity
colormap([0 0 0; jet]);
% colorbar;

subplot(3,1,2)
pcolor(x,y,ZAir)
title('0dBm transmit power decay in AIR. BaseStation')
xlabel('-150m < BaseStation < 150m') % x-axis label
ylabel('-150m < BaseStation < 150m') % y-axis label
shading interp;
set(gca, 'clim', [-94 0]); %-94dBm is antenna receiver sensitivity
colormap([0 0 0; jet]);
% colorbar;

subplot(3,1,3)
pcolor(x,y,ZAirNorth)
title('0dBm transmit power decay in AIR. NorthStation')
xlabel('-150m < BaseStation < 150m') % x-axis label
ylabel('-150m < BaseStation < 150m') % y-axis label
shading interp;
set(gca, 'clim', [-94 0]); %-94dBm is antenna receiver sensitivity
colormap([0 0 0; jet]);
% colorbar;

figure(3)
hold on
pcolor(x,y,ZAIRCombined)
title('0dBm transmit power decay in AIR. Combined Stations')
xlabel('-150m < BaseStation < 150m') % x-axis label
ylabel('-150m < BaseStation < 150m') % y-axis label
shading interp;
set(gca, 'clim', [-94 0]); %-94dBm is antenna receiver sensitivity
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'r')
hold off


%% Plotting Signal Range in AIR for -24dBm
figure(4)
hold on
pcolor(x(71:81),y(71:81),ZAir_min(71:81,71:81))
title('-24dBm transmit power decay in AIR. BaseStation')
xlabel('-15m < BaseStation < 15m') % x-axis label
ylabel('-15m < BaseStation < 15m') % y-axis label
shading interp;
set(gca, 'clim', [-94 0]); %-94dBm is antenna receiver sensitivity
colormap([0 0 0; jet]);
colorbar;

%Ellipse
a=10; % horizontal radius
b=2; % vertical radius
x0=0; % x0,y0 ellipse centre coordinates
y0=0;
t=-pi:0.01:pi;
x_ellipse=x0+a*cos(t);
y_ellipse=y0+b*sin(t);
plot(x_ellipse,y_ellipse,'r')
hold off

figure(5)
hold on
pcolor(x(71:81),y(71:81),ZAIRCombined_min(71:81,71:81))
title('-24dBm transmit power decay in AIR. Combined Stations')
xlabel('-15m < BaseStation < 15m') % x-axis label
ylabel('-15m < BaseStation < 15m') % y-axis label
shading interp;
set(gca, 'clim', [-94 0]);
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'r')
hold off

%% Plotting Signal Range in Shannon Engineering Building for 0dBm
figure(6)
hold on
pcolor(x(34:118),y(34:118),ZOffice(34:118,34:118))
title('0dBm transmit power decay in office. BaseStation')
xlabel('-42m < BaseStation < 42m') % x-axis label
ylabel('-42m < BaseStation < 42m') % y-axis label
shading interp;
set(gca, 'clim', [-94 0]); %-94dBm is antenna receiver sensitivity
colormap([0 0 0; jet]);
colorbar;

%Ellipse
a=60; % horizontal radius
b=15; % vertical radius
x0=0; % x0,y0 ellipse centre coordinates
y0=0;
t=-pi:0.01:pi;
x_ellipse=x0+a*cos(t);
y_ellipse=y0+b*sin(t);
plot(x_ellipse,y_ellipse,'r')
hold off

figure(7)
hold on
pcolor(x(34:118),y(34:118),ZOfficeCombined(34:118,34:118))
title('0dBm transmit power decay in office. BaseStation')
xlabel('-42m < BaseStation < 42m') % x-axis label
ylabel('-42m < BaseStation < 42m') % y-axis label
shading interp;
set(gca, 'clim', [-94 0]); %-94dBm is antenna receiver sensitivity
colormap([0 0 0; jet]);
colorbar;
plot(x_ellipse,y_ellipse,'r')
hold off

