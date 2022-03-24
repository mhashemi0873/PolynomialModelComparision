#!/bin/bash

cwd=$(pwd)
echo $cwd

alg="advi"

iter=200000
tol_rel_obj=0.000000001

num_warmup=1000
num_samples=2000
delta=0.85
max_depth=10


Nchain=5
Max_run=11


data_input_R=data_input_files/data_input.R
data_input_npz=data_input_files/data_input.npz
data_input_R_npz=data_input_files/data_input.R.npz

#rm -rf output*


declare -a array=("Hypo1" "Hypo2" "Hypo3" "Hypo4")

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

    mkdir -p  data_output_CV_${alg}_${model}

    log_file=report_output_CV_${model}.txt

    j=1

    while [ $j -le $Max_run ] 
    do

        if [ ${alg} == "advi" ]; then

                echo "...Running ADVI"$j" started..."

                ./$model id=$((100*$j))\
                    variational\
                    iter=$iter tol_rel_obj=0.0001 \
                    data file=${data_input_R}\
                    output diagnostic_file=data_output_CV_${alg}_${model}/output_${alg}_diag_${model}_$j.R\
                    file=data_output_CV_${alg}_${model}/output_${alg}_${model}_$j.csv refresh=1 \
                    &> data_output_CV_${alg}_${model}/output_${alg}_${model}_$j.out 
        
                echo "...checking convergence of advi"$j"..."
                advi_convergence_check=$(python checking_converged_${alg}.py data_output_CV_${alg}_${model}/output_${alg}_${model}_$j.out  2>&1 )
                echo $advi_convergence_check

                if [ "$advi_convergence_check" == "advi converged" ]; then
                        echo "ADVI converged for run"$j 
                        echo "ADVI converged for run"$j >> ${log_file}
                        echo "...saving output for  advi"$j"..." 
                        ((j++))
                else
                        echo "...removing output_advi"$j"..."
                        rm -rf data_output_CV_${alg}_${model}/output_${alg}_${model}_$j.{out,R,csv}
                fi



                if [ $j -eq $Nchain ]; then
                        echo "ADVI converged for all chains."  
                        echo "ADVI converged for all chains."  >> ${log_file}
                        break
                fi  

                if [ $j -eq $Max_run ]; then
                        echo "ADVI arrived max iterations."  
                        echo "ADVI arrived max iterations."  >> ${log_file}
                        break
                fi  



        else
                echo "...Running HMC"$j" started..."
                ./$model id=$((100*$j))\
                    sample\
                    save_warmup=0 num_warmup=$num_warmup num_samples=$num_samples\
                    adapt delta=$delta \
                    algorithm=hmc engine=nuts max_depth=$max_depth \
                    data file=${data_input_R}\
                    output diagnostic_file=data_output_CV_${alg}_${model}/output_${alg}_diag_${model}_$j.R\
                    file=data_output_CV_${alg}_${model}/output_${alg}_${model}_$j.csv refresh=1 \
                    &> data_output_CV_${alg}_${model}/output_${alg}_${model}_$j.out 
 

                echo "...checking convergence of hmc"$j"..."
                hmc_convergence_check=$(python checking_converged_${alg}.py data_output_CV_${alg}_${model}/output_${alg}_${model}_$j.out  2>&1 )
                echo $hmc_convergence_check

                if [ "$hmc_convergence_check" == "hmc converged" ]; then
                        echo "HMC converged for run"$j 
                        echo "HMC converged for run"$j >> ${log_file}
                        echo "...saving output for  hmc"$j"..." 
                        ((j++))
                else
                        echo "...removing output_hmc"$j"..."
                        rm -rf data_output_CV_${alg}_${model}/output_${alg}_${model}_$j.{out,R,csv}
                fi



                if [ $j -eq $Nchain ]; then
                        echo "HMC converged for all chains."  
                        echo "HMC converged for all chains."  >> ${log_file}
                        break
                fi  

                if [ $j -eq $Max_run ]; then
                        echo "HMC arrived max iterations."  
                        echo "HMC arrived max iterations."  >> ${log_file}
                        break
                fi  


        fi

    done
     

    wait

    echo  ..................................................................................................................
    python ComputeICcsv.py    ${data_input_npz}  ${model}.stan   data_output_CV_${alg}_${model}/output_${alg}_${model}_?.csv
    echo  ...................................................................................................
    python ComputePSIScsv.py  ${data_input_npz}  ${model}.stan   data_output_CV_${alg}_${model}/output_${alg}_${model}_?.csv
    echo  ..................................................................................................................

    wait

done

echo "Jobe done!"
