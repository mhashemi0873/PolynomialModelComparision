#!/bin/bash

cwd=$(pwd)

alg="hmc"

iter=100000
tol_rel_obj=0.000001

num_warmup=500
num_samples=500
delta=0.9
max_depth=10


Nchain=5
Max_run=11

data_input_R=data_input_files/data_input.R
data_input_npz=data_input_files/data_input.npz
data_input_R_npz=data_input_files/data_input.R.npz

declare -a array=("epileptor_cen_hypo1"     "epileptor_cen_hypo2"       "epileptor_cen_hypo3"   
                 "epileptor_noncen_hypo1"   "epileptor_noncen_hypo2"    "epileptor_noncen_hypo3"  
                 )

arraylength=${#array[@]}


for (( i=1; i<${arraylength}+1; i++ ));
do

    echo $i " / " ${arraylength} " : " ${array[$i-1]}

    model=${array[$i-1]}


    #rm -rf report_convergence_CV*
    log_file=report_convergence_CV_${alg}_${model}.txt
    
    echo "Job Started!" >> ${log_file}


    echo  ......................................................
    echo creating models ...>> ${log_file}
    cd $cwd/cmdstan && make $cwd/${array[$i-1]} && cd ..
    echo  compiled models ... >> ${log_file}
    echo $(pwd) >> ${log_file}
    echo  ......................................................


    mkdir -p  data_output_CV_${alg}_${model}
    

    echo "Running Started for" ${alg}_${model} >> ${log_file}


    j=1

    while [ $j -le $Max_run ] 
                do

                    if [ ${alg} == "advi" ]; then

                            echo "...running ADVI"$j" started..." >> ${log_file}

                            ./$model id=$((100*$j+$k))\
                                variational\
                                iter=$iter tol_rel_obj=0.0001 \
                                data file=${data_input_R}\
                                output diagnostic_file=data_output_CV_${alg}_${model}/output_${alg}_diagnostic_${model}_$j.R\
                                file=data_output_CV_${alg}_${model}/output_${alg}_${model}_$j.csv refresh=1 \
                                &> data_output_CV_${alg}_${model}/output_${alg}_${model}_$j.out 
                    
                            echo "...checking convergence of advi"$j"..." >> ${log_file}
                            advi_convergence_check=$(python checking_converged_${alg}.py data_output_CV_${alg}_${model}/output_${alg}_${model}_$j.out   2>&1 )
                            echo $advi_convergence_check >> ${log_file}

                            if [ "$advi_convergence_check" == "advi converged" ]; then
                                    echo "ADVI converged for run"$j >> ${log_file}
                                    ((j++))
                            else
                                    echo "...removing output_advi"$j"..."
                                    rm -rf data_output_CV_${alg}_${model}/output_${alg}_${model}_$k-$j.{out, R, csv}
                            fi


                            if [ $j -eq $Nchain ]; then
                                    echo "ADVI converged for all chains." >> ${log_file}
                                    break
                            fi  

                            if [ $j -eq $Max_run ]; then
                                    echo "ADVI arrived max iterations." >> ${log_file}
                                    break
                            fi  

                    else
                            echo "...running HMC"$j" started..." >> ${log_file}

                            ./$model id=$((100*$j+$k))\
                                sample\
                                save_warmup=0 num_warmup=$num_warmup num_samples=$num_samples\
                                adapt delta=$delta \
                                algorithm=hmc engine=nuts max_depth=$max_depth \
                                data file=${data_input_R}\
                                output diagnostic_file=data_output_CV_${alg}_${model}/output_${alg}_diagnostic_${model}_$j.R\
                                file=data_output_CV_${alg}_${model}/output_${alg}_${model}_$j.csv refresh=1 \
                                &> data_output_CV_${alg}_${model}/output_${alg}_${model}_$j.out 
             

                            echo "...checking convergence of hmc"$j"..." >> ${log_file}
                            hmc_convergence_check=$(python checking_converged_${alg}.py data_output_CV_${alg}_${model}/output_${alg}_${model}_$j.out   2>&1 )
                            echo $hmc_convergence_check >> ${log_file}

                            if [ "$hmc_convergence_check" == "hmc converged" ]; then
                                    echo "HMC converged for run"$j >> ${log_file}                                   
                                    ((j++))
                            else
                                    echo "...removing output_hmc"$j"..."
                                    rm -rf data_output_CV_${alg}_${model}/output_${alg}_${model}_$j.{out, R, csv}
                            fi


                            if [ $j -eq $Nchain ]; then
                                    echo "HMC converged for all chains." >> ${log_file}
                                    break
                            fi  

                            if [ $j -eq $Max_run ]; then
                                    echo "HMC arrived max iterations." >> ${log_file}
                                    break
                            fi  


                    fi

    done

    

    wait
    echo  ..................................................................................................

    # echo  ..................................................................................................................
    # python ComputeIC.py    ${data_input_npz}  ${model}   data_output_CV_${alg}_${model}/output_${alg}_${model}_?.csv
    # echo  ...................................................................................................
    # python ComputePSIS.py  ${data_input_npz}  ${model}   data_output_CV_${alg}_${model}/output_${alg}_${model}_?.csv
    # echo  ..................................................................................................................

    # wait

    echo "Running Finished for" ${alg}_${model} >> ${log_file}

done

wait
echo  ..........................................................................................
echo  ..........................................................................................
echo "Job done!" >> ${log_file}