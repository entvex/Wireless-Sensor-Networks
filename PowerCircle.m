clc; clear;

max_datarate   = 250*1000*8;               %250k-byte Telos_B datasheet
packagesize    = 128*1000*8;               %128k-byte WSN Problem Description
TransmitPeriod = packagesize/max_datarate; %Second

time       = 1;                              %Second
sleep_duty = time-TransmitPeriod*time;       %Sleep period for one package every second
R = 1;                                       %Measurement Shunt-Resistance
I_tx      = 18.3*10.^(-3);                   %Transmit current
I_rx      = 23.0*10.^(-3);                   %Receive Current
I_sleep   = 1*10.^(-6);                      %Sleep current
Ptx       = I_tx*R^(2) * TransmitPeriod;     %Transmit Power
Prx       = I_rx*R^(2) * TransmitPeriod;     %Receive Power 
Ptsleep   = I_sleep*R^(2) * TransmitPeriod;  %Sleep Power
Ptx_Total = Ptx + Ptsleep;                   %Power without the sleep overshoot power
P_Total   = Ptx_Total + Prx;                 %Total receive and transmitting power

% Antennasize = 3.5cm and freq = 2.4Gb
% https://www.everythingrf.com/rf-calculators/antenna-near-field-distance-calculator
d0 = 0.0196; %meter 
N = 100; %meter from the base station
x = linspace(-N,N,N+1);  %100 meter in free space from Telos_B datasheet!
y = linspace(-N,N,N+1);  %100 meter in free space from Telos_B datasheet!

gammaAIR    = 2;
gammaOffice = 5.5;
[X,Y] = meshgrid(x,y);
d = sqrt(X.^(2)+Y.^(2)); %euclidean distance
d(N/2+1,N/2+1) = 1;      %to avoid inf number in the center!
ZAir    = 10*log((1000*Ptx.*((d0./d).^gammaAIR)./Ptx));   %dBm
ZOffice = 10*log((1000*Ptx.*((d0./d).^gammaOffice)./Ptx)); %dBm
ZxAIR = Ptx*((d0./x).^gammaAIR);                          %x-axis AIR!
ZxAIR(51) = ZxAIR(50);
ZxOffice = abs(Ptx*((d0./x).^gammaOffice));               %x-axis Office!
ZxOffice(51) = ZxOffice(50);

Zm03_AIR  = 10*log((1000*Ptx.*((d0./0.3).^gammaAIR)./Ptx)) %distance = kissing the mote (dBm)
Zm1_AIR   = ZAir(N/2+1,N/2+1) %  1m distance (dBm)
Zm50_AIR  = ZAir(26,51)       % 50m distance (dBm)
Zm100_AIR = ZAir(1,51)        %100m distance (dBm)

Zm03_Office  = 10*log((1000*Ptx.*((d0./0.3).^gammaOffice)./Ptx)) %distance = kissing the mote (dBm)
Zm1_Office   = ZOffice(N/2+1,N/2+1) %  1m distance (dBm)
Zm50_Office  = ZOffice(26,51)       % 50m distance (dBm)
Zm100_Office = ZOffice(1,51)        %100m distance (dBm)

figure(1)
subplot(2,1,1)
pcolor(x,y,ZAir)
subplot(2,1,2)
pcolor(x,y,ZOffice)

figure(2)
subplot(2,1,1)
plot(ZxAIR)
subplot(2,1,2)
plot(ZxOffice)

acceptable_dBm = 90;
outOfRange = find(abs(ZAir)>acceptable_dBm);
ZAir(outOfRange) = Zm1_AIR;

acceptable_dBm = 360;
outOfRange = find(abs(ZOffice)>acceptable_dBm);
ZOffice(outOfRange) = Zm1_Office;

figure(3)
subplot(2,1,1)
pcolor(x,y,ZAir)
subplot(2,1,2)
pcolor(x,y,ZOffice)

%% Overshoot -os = overshoot
os_time       = 0.05; %sec 
os_Persentage = 0.4;
os_Top        = Ptx * os_Persentage;
os_center     = os_time/2; %sec

x = [0:.001:os_time];
f = os_Top * exp(-((x-os_center).^(2)/0.0001));
fun = @(x) os_Top * exp(-((x-os_center).^(2)/0.0001));
OS_power = integral(fun,0,os_time);
figure(4)
plot(x,f);

% AA Battery https://en.wikipedia.org/wiki/AA_battery "RAM"
V  = 1.5;
Ah = 2*2600*10^(-3); %mAh for two batteries
BatteryPower = V*Ah
powerTime_nosleep     = BatteryPower/(I_tx*R^(2))         %Lifetime in hours //Only Transmitting
powerTime_noOvershoot = BatteryPower/Ptx_Total            %Lifetime in hours //Transmitting and sleeping
powerTime_Overshoot   = BatteryPower/(Ptx_Total+OS_power) %Lifetime in hours //Transmitting and sleeping with overshoot!
powerTimeTotal        = BatteryPower/(P_Total+OS_power)   %Lifetime in hours //Transmitting and sleeping with overshoot!

