# nv-tools
Nvidia Control Scripts

fan-control.sh inspired by post by 'Jeremiah' on Ubuntu forum for controlling nvidia fans with a fan ratio based on temperature

original script updated to dyamically detect number of installed Nvidia GPUs and independant setting of fan for each GPU based on 
temperature. Script uses 'nvidia-settings' and 'nvidia-smi' to determine temps and set new fanspeed. 

Features
* multi-GPU support with independant control per GPU
* display overclock info and temp limits from installed GPUs at start
* if temp is same as prior check, don't change fan settings
* if fan is at max, don't change when temp increases



