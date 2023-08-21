redirect_cmd() {
    if [ $RUN -eq 1 ]; then
        "$@" >> ~/temp_job_conf.yaml
    else
        "$@"
    fi
}


SCRIPT_PATH="$(dirname -- "${BASH_SOURCE[0]}")"

#ENV VARIABLES
. ${SCRIPT_PATH}/oc_env.sh

#NFS_CLAIM
tmp_path=$NFS_CLAIM_PATH

cnt=1
while [ ! -z $tmp_path ];do
    NFS_CLAIM=`echo $tmp_path | awk -F "/" '{print $NF}'`
    if [ -z $NFS_CLAIM ];then
        cnt=$((cnt + 1))
    else
        tmp_path=""
    fi
    tmp_path=`echo $tmp_path | rev | cut -c2- | rev`
done
NFS_CLAIM_PATH=`echo $NFS_CLAIM_PATH | rev | cut -c${cnt}- | rev`


IMAGE=$DEFAULT_DOCKER_IMAGE
NAME=""
DIR=`echo $PWD | sed "s|${NFS_CLAIM_PATH}|/nfs/|"`  #"/nfs"
CMD=""
CPU=$DEFAULT_CPU
MEM=$DEFAULT_MEM
GPU=0
GPU_TYPE=""
BREAK=0
RUN=0
SHELL=0
ROOT=0

while [[ "$#" -gt 0 ]];do
  case $1 in
    -i|--image)
      IMAGE=$2
      ;;
    -n|--name)
      NAME=$2
      ;;
    -d|--dir)
      DIR=$2
      ;;
    -c|--cmd)
      CMD=$2
      ;;
    -p|--cpu)
      CPU=$2
      ;;
    -m|--mem)
      MEM=$2
      ;;
    -g|--gpu)
      GPU=$2
      ;;
    -t|--gputype)
      GPU_TYPE=$2
      ;;
    -s|--shell)
      SHELL=1
      ;;
    -u|--root)
      ROOT=1
      ;;
    -r|--run)
      RUN=1
	  echo "" > ~/temp_job_conf.yaml
      ;;
	-h|--help)
      BREAK=1
      echo "gen_job_conf.sh [OPTION]"
	  echo "  -i, --image      DOCKER_IMAGE, Default: ${IMAGE}"
	  echo "  -n|--name        Suffix to Job Name"
	  echo "  -d|--dir         Run Directory, Default: ${DIR}"
	  echo "  -c|--cmd         Python Run Command"
	  echo "  -p|--cpu         CPU, Default: ${CPU}"
	  echo "  -m|--mem         Memory, Default: ${MEM}"
	  echo "  -g|--gpu         GPU Count, Default: ${GPU}"
	  echo "  -t|--gputype     Select GPU Node ['TITAN','2080ti','3090','A6000']"
	  echo "  -r|--RUN         Execute the YAML, Default: Print YAML"
	  echo "  -s|--shell	   Run bash, Default: python3"
	  echo "  -u|--root        Run container with root access"
      ;;
  esac
  shift
done

if [ $BREAK -eq 0 ];then
#Check Required Parameters

#CPU Greater than 0 and not empty
if [[ $CPU -lt 1 || -z $CPU ]];then
    echo "ERROR: CPU must be greater than 0. See --help for more info."
    BREAK=1
fi
#Mem Greater than 0 and not empty
if [[ $MEM -lt 1 || -z $MEM ]];then
    echo "ERROR: Memory must be greater than 0. See --help for more info."
    BREAK=1
fi

fi

fmt_cmd()
{
        arr=(`echo $CMD | sed 's/ /\n/g'`)
        cnt=${#arr[*]}
        run_file=${arr[0]}
        params=""
        prev_param=""
        i=1
        while [ $i -lt $cnt ];do
          if [[ ${arr[$i]} == -* && ${arr[$i]} != --* ]];then
          	if [[ $prev_param != "" ]];then
          		params+=${prev_param}"|"
  		fi
                prev_param=${arr[$i]}
          elif [[ $prev_param != "" ]];then
                params+=${prev_param}${arr[$i]}"|"
                prev_param=""
          else
                params+=${arr[$i]}"|"
          fi
          i=$(($i+1))
        done
        if [[ $prev_param != "" ]];then
  		params+=${prev_param}"|"
	fi
}

#NFS_CLAIM
tmp_path=$NFS_CLAIM_PATH

cnt=1
while [ ! -z $tmp_path ];do 
    NFS_CLAIM=`echo $tmp_path | rev | cut -c${cnt}- | rev | awk -F "/" '{print $NF}'`
    if [ -z $NFS_CLAIM ];then
        cnt=$((cnt + 1))
    else 
        tmp_path=""
    fi
done


#MAIN

if [ $BREAK -eq 0 ];then

    #JOB NAME
	meta_name=`basename $DIR`"-"`echo $CMD | cut -d "" -f1 | cut -d "." -f1 `
	if [[ ${NAME} != "" ]];then
		meta_name="${meta_name}-${NAME}"
	fi
	meta_name=`echo $meta_name | sed "s/\_/-/g" | sed "s/ /-/g" | sed "s|/|-|g" | awk '{print tolower($0)}'`
	
    #GPUs
    if [ $GPU -gt 0 ];then
		gpu="nvidia.com/gpu: ${GPU}"
	else
		gpu=""
	fi

    #SHELL or PYTHON
	if [ $SHELL -eq 1 ];then
        #BASH JOB
        prg="bash"
	else
		prg="python3"
    fi

    #RUN as ROOT
    if [ $ROOT -eq 1 ];then
            #BASH JOB
            root="serviceAccount: containerroot"
    else
            root=""
    fi

    #YAML
	redirect_cmd echo "apiVersion: batch/v1"
	redirect_cmd echo "kind: Job"
	redirect_cmd echo "metadata:"
	redirect_cmd echo "  name: ${meta_name}"
	redirect_cmd echo "  namespace: ${OC_PROJECT}"
	redirect_cmd echo "spec:"
	redirect_cmd echo "  backoffLimit: 0"
	redirect_cmd echo "  template:"
	redirect_cmd echo "    metadata:"
	redirect_cmd echo "      name: ${meta_name}"
	redirect_cmd echo "    spec:"
	redirect_cmd echo "      containers:"
	redirect_cmd echo "      - name: ${meta_name}-cont"
	redirect_cmd echo "        image: '${IMAGE}'"
	redirect_cmd echo "        workingDir: ${DIR}"
	redirect_cmd echo "        command:"
	redirect_cmd echo "            - ${prg}"
	redirect_cmd echo "        args:"
	fmt_cmd
	redirect_cmd echo "            - ${run_file}"
	param_arr=(`echo $params | sed 's/|/\n/g'`)
	cnt=${#param_arr[*]}
	i=0
	while [ $i -lt $cnt ];do
		redirect_cmd echo "            - '${param_arr[$i]}'"
		i=$(($i+1))
	done
	redirect_cmd echo "        resources:"
	redirect_cmd echo "            requests:"
	redirect_cmd echo "              cpu: '${CPU}m'"
	redirect_cmd echo "              memory: '${MEM}Gi'"
	redirect_cmd echo "              ${gpu}"
	redirect_cmd echo "            limits:"
	redirect_cmd echo "              cpu: '${CPU}m'"
	redirect_cmd echo "              memory: '${MEM}Gi'"
	redirect_cmd echo "              ${gpu}"
	redirect_cmd echo "        imagePullPolicy: IfNotPresent"
	redirect_cmd echo "        volumeMounts:"
	redirect_cmd echo "            - name: nfs-access"
	redirect_cmd echo "              mountPath: /nfs"
        redirect_cmd echo "      ${root}"
	redirect_cmd echo "      volumes:"
	redirect_cmd echo "        - name: nfs-access"
	redirect_cmd echo "          persistentVolumeClaim:"
	redirect_cmd echo "            claimName: ${NFS_CLAIM}"
	if [[ $GPU_TYPE == "TITAN" ]];then
		redirect_cmd echo "      nodeSelector:"
		redirect_cmd echo "            node-role.ida/gputitan: 'true'"
	elif [[ $GPU_TYPE == "2080ti" ]];then
		redirect_cmd echo "      nodeSelector:"
		redirect_cmd echo "            node-role.ida/gpu2080ti: 'true'"
        elif [[ $GPU_TYPE == "3090" ]];then
                redirect_cmd echo "      nodeSelector:"
                redirect_cmd echo "            node-role.ida/gpu3090: 'true'"
        elif [[ $GPU_TYPE == "A6000" ]];then
                redirect_cmd echo "      nodeSelector:"
                redirect_cmd echo "            node-role.ida/gpua6000: 'true'"
	fi
	redirect_cmd echo "      restartPolicy: Never"
	
	if [ $RUN -eq 1 ];then
		#RUN JOB
		oc create -f ~/temp_job_conf.yaml
	fi
fi
