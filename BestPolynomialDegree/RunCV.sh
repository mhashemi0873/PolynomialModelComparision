#!/bin/bash

cwd=$(pwd)
echo $cwd

alg="hmc"

iter=200000
tol_rel_obj=0.0001

num_warmup=200
num_samples=300
delta=0.85
max_depth=10


Nchain=4
MaximumIteration=10

rm -rf output*

declare -a array=("model_poly2")

arraylength=${#array[@]}


for (( i=1; i<${arraylength}+1; i++ ));
do

    echo $i " / " ${arraylength} " : " ${array[$i-1]}

    model=${array[$i-1]}

    echo  ......................................................
    echo creating models ...
    cd $cwd/cmdstan && make $cwd/${array[$i-1]} && cd ..
    echo  compiled models ... 
    echo $(pwd) 
    echo  ......................................................

    maxj=0
    j=1

	while [ $j -le $Nchain ]
	do
        if [ ${alg} == "advi" ]; then

        		echo "Running ADVI..."$j" started..."

        		./$model id=$j\
        	        variational iter=$iter tol_rel_obj=0.0001 \
        	        data file=data_input.R\
        	        output file=output_${model}_${alg}_$j.csv refresh=1 \
        	        &> output_${model}_${alg}_$j.out 
        
        else
                echo "Running HMC..."$j" started..."

                ./$model id=$j\
                    sample num_warmup=$num_warmup num_samples=$num_samples\
                    adapt \
                    delta=$delta \
                    algorithm=${alg} \
                    engine=nuts \
                    max_depth=$max_depth \
                    data file=data_input.R\
                    output file=output_${model}_${alg}_$j.csv refresh=1 \
                    &> output_${model}_${alg}_$j.out 

        fi    


        output=$(python check_converged_${alg}.py output_${model}_${alg}_$j.out 2>&1 )
        
        echo $output

        if [ "$output" == "Succeed run" ]; then
		     echo "...saving try"$j"..."
		     ((j++))
		else
			 rm -rf output_${model}_${alg}_$j.{out,csv}
		     echo "...removing run"$j"..."
		fi
         
        ((maxj++))
 
        if [ $maxj == $MaximumIteration ]; then
            break
            echo "${alg} Failed!:"
        fi

	done
     
	echo "Max interation was:"$maxj

    wait
    echo  .............................................................................
	python ComputeICcsv.py data_input.npz ${model}.stan output_${model}_${alg}_?.csv
    echo  .............................................................................
    python ComputePSIScsv.py data_input.npz ${model}.stan output_${model}_${alg}_?.csv 

	wait

done