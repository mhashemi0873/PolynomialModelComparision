#!/bin/bash

alg="hmc"
Nchain=4
iter=2000

data_input_npz=data_input_files/data_input.npz

declare -a array=("model_poly1" "model_poly2" "model_poly3" "model_poly5")

arraylength=${#array[@]}

for (( i=1; i<${arraylength}+1; i++ ));
do
    echo $i " / " ${arraylength} " : " ${array[$i-1]}

    model=${array[$i-1]}

    mkdir -p  data_output_IC_${model}

    rm -rf data_output_IC_${model}/output*
 

    j=1

    for j in `seq $Nchain`
    do
        echo "...Running Pystan"$j" started..."

        python RunPyStan4IC.py ${data_input_npz}  ${model}.stan  ${alg} ${iter} data_output_IC_${model}/output_${model}_$j.npz 

    done


    echo "...Running finnished."

    echo  ..................................................................................................

    echo "...Computing Information criteria..."

    python ComputeIC.py ${data_input_npz} ${model}.stan data_output_IC_${model}/output_${model}_?.npz 

    echo "...Computing IC terminated."

    echo "...Computing PSIS-LOO..."

    python ComputePSIS.py ${data_input_npz} ${model}.stan data_output_IC_${model}/output_${model}_?.npz

    echo "...Computing PSIS terminated."
 
    echo  ..................................................................................................
    wait
done

echo "Jobe done!"
