#!/bin/bash
# script modified from Jeremiah's example in Ububtu forum: 
# https://askubuntu.com/questions/766110/adjusting-an-nvidia-gpus-fan-curve
# set fan percentage to .028*(degreesC^2)

# Logic added by Anton Rager to manage multiple GPUs
#
# nvidia-xconfig needs to be configured
# for multi-GPU support and coolbits for fan control (coolbits 4). coolbits here also allows OC
#
# 'cd /etc/X11/'
# 'sudo nvidia-xconfig --enable-all-gpus'
# 'sudo nvidia-xconfig --cool-bits=28' 

# startup delay if used with init
# sleep 30

# set persistance mode
nvidia-smi -pm 1

# show GPUs in system
nvidia-smi -L

# index list to iterate thru
gpuindexlist=`nvidia-smi -L | sed -e 's/GPU //'| sed -e 's/:.*//'`

while read gpu; do

  # clocks and poweR power
  gpuclock=`nvidia-settings -q "[gpu:$gpu]/GPUGraphicsClockOffset" | grep "Attribute" | sed -e 's/.*): //' | sed -e 's/\.//'`
  memclock=`nvidia-settings -q "[gpu:$gpu]/GPUMemoryTransferRateOffset" | grep "Attribute" | sed -e 's/.*): //' | sed -e 's/\.//'`
  echo "overclock GPU $gpuclock, overclock memory: $memclock"
  # temp limits
  tempslowdown=`nvidia-smi -q -i $gpu -d TEMPERATURE | grep "GPU Slowdown Temp" | sed -e 's/.*: //'`
  tempshutdown=`nvidia-smi -q -i $gpu -d TEMPERATURE | grep "GPU Shutdown Temp" | sed -e 's/.*: //'`
  tempmaxop=`nvidia-smi -q -i $gpu -d TEMPERATURE | grep "GPU Max Operating Temp" | sed -e 's/.*: //'`
  echo "seting up fan control for GPU $gpu"
  echo "--max safe temp: $tempmaxop"  
  echo "--slowdown temp: $tempslowdown"  
  echo "--shutdown temp: $tempshutdown"  
  fanspeed[$gpu]="30"
  cputemp[$gpu]="0"

  nvidia-settings -a "[gpu:$gpu]/GPUFanControlState=1" &> /dev/null  
  nvidia-settings -a "[fan:$gpu]/GPUTargetFanSpeed=${fanspeed[$gpu]}"
  # &> /dev/null 

done <<< "$gpuindexlist"

while true
do

  # loop thru gpu indexes
  while read gpu; do

    priortemp[$gpu]=${cputemp[$gpu]}
    priorfan[$gpu]=${fanspeed[$gpu]}
    cputemp[$gpu]="$(nvidia-smi -i $gpu | grep -owEe '[0-9]+C' | sed -e 's/C//')"

    #cputemp[$gpu]=`nvidia-smi -i $gpu --query-gpu=temperature.gpu --format=csv,noheader,nounits`
    # check if we have temp change. Sleep if no change
    if [[ ${priortemp[$gpu]} -ne ${cputemp[$gpu]} ]]
    then
      fanspeed[$gpu]=$((${cputemp[$gpu]} ** 2))
      fanspeed[$gpu]=$((${fanspeed[$gpu]} / 50))
      if [[ ${fanspeed[$gpu]} -gt 100 ]]
      then
        fanspeed[$gpu]=100
      fi

      # check if fan is already at max and don't set again if at max/same val
      if [[ ${priorfan[$gpu]} -ne ${fanspeed[$gpu]} ]]
      then
        echo "GPU $gpu temp: ${cputemp[$gpu]}""C, setting speed: ${fanspeed[$gpu]}""%"
        nvidia-settings -a "[fan:$gpu]/GPUTargetFanSpeed=${fanspeed[$gpu]}" &> /dev/null 
      else
        echo "GPU $gpu temp: ${cputemp[$gpu]}""C, speed: ${fanspeed[$gpu]}""%"
      fi
    fi
  done <<< "$gpuindexlist"
  sleep 8
done
