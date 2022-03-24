#!/bin/bash

alg="hmc"
Nchain=4
iter=1000

N_dataset=10


declare -a array=("HypoBad" "HypoGood"  "HypoUgly" )

arraylength=${#array[@]}

for (( i=1; i<${arraylength}+1; i++ ));
do

	echo $i " / " ${arraylength} " : " ${array[$i-1]}

    model=${array[$i-1]}

    mkdir -p  data_output_IC_${model}

    rm -rf data_output_IC_${model}/output*

    echo "...Running Pystan..."

	for ((k = 1; k <= N_dataset; k++));
	do
        echo "Running data_input"$k" started..."

            for j in `seq $Nchain`
	        do 

                echo "Running chain"$j" started..."

			    python RunPyStan4IC.py data_input/data_input$k.npz ${model}.stan  ${alg} ${iter} data_output_IC_${model}/output$k-$j.npz 

			done
			            
	done
		 
echo "...Computing Information criteria..."

python ComputeIC_Hypos.py data_input.npz ${model}.stan data_output_IC_${model}

echo "...Computing IC terminated."

echo "...Computing PSIS-LOO..."

python ComputePSIS_Hypos.py data_input.npz ${model}.stan data_output_IC_${model}

echo "...Computing PSIS terminated."
		 
echo  ..................................................................................................
wait

done

echo "Jobe done!"
