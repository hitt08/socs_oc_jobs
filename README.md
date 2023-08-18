# SoCS OpenShift Cluster Jobs

## 1) oc_env.sh
Environment Variables

```
#REQUIRED -- MUST BE UPDATED
export OC_PROJECT=<project_name>             #e.g. ****project
export NFS_CLAIM_PATH=<path_to_nfs_claim>    #e.g. /home/${USER}/*****vol1claim
```
```
#OPTIONAL -- Default Parameters for the Jobs
export DEFAULT_DOCKER_IMAGE="pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime"
export DEFAULT_CPU=4000
export DEFAULT_MEM=16
```


## 2) gen_job_conf.sh
Create the YAML file and submit it to the Cluster

"-r|--RUN" option requires login to the cluster (```oc login```)

```
gen_job_conf.sh [OPTIONS]
  -i, --image      DOCKER_IMAGE
  -n|--name        Suffix to Job Name
  -d|--dir         Run Directory
  -c|--cmd         Python Run Command
  -p|--cpu         CPU
  -m|--mem         Memory
  -g|--gpu         GPU Count
  -t|--gputype     Select GPU Node ['TITAN','2080ti','3090','A6000']
  -r|--RUN         Execute the YAML (By Default, only displays the YAML)
  -s|--shell	   Run bash (By Default: python3)
  -u|--root        Run container with root access
```

```
#e.g.

$ gen_job_conf.sh -d "/nfs/path_to_code/" -c "echo.py -s 'Hello!' --repeat 10" -i "pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime" -r
job.batch/path-to-code-echo created
```

<br>
  
By default, the script converts the current directory path to the NFS path and uses it as the run directory. So, you can directly run the script from anywhere within the NFS volume on the headnode.
For example, if the code file that is to be run on the cluster exists on: ```/nfs/path_to_code/echo.py```, you can create the job as follows:
```
cd /home/${USER}/${USER}vol1claim/path_to_code/
<path_to>/gen_job_conf.sh -c "echo.py -s 'Hello!' --repeat 10" -i "pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime" 
```

<br>
  
The script creates the job name based on the current directory and the code script. Additionally, you can pass a suffix to the job name ("-n|--name") to differentiate between runs (e.g. for different parameter configurations). 
```
#e.g.

$ <path_to>/gen_job_conf.sh -c "echo.py -s 'Hello!' --repeat 10" -i "pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime" -n "hello10" -r
job.batch/path-to-code-echo-hello10 created
```

<br>
  

## 3) delete_jobs.sh
Delete an existing job or multiple jobs with a name pattern.

```
delete_jobs.sh <jobname or pattern string> [-p|--pattern]
  -p, --pattern    Use pattern matching
```

<br>
  

## Alias
Optionally, for easy usage, set up the following aliases (e.g. in bashrc, bash_profile or any other startup script:

```
alias 'runjob=. <path_to>/gen_job_conf.sh'
alias 'deletejob=. <path_to>/delete_jobs.sh'
```

```
#e.g.

$ runjob -c "echo.py -s 'Hello!' --repeat 1" -i "pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime" -n "hello1" -r
job.batch/path-to-code-echo-hello1 created
$ runjob -c "echo.py -s 'Hello!' --repeat 10" -i "pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime" -n "hello10" -r
job.batch/path-to-code-echo-hello10 created
$ runjob -c "echo.py -s 'Hello!' --repeat 20" -i "pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime" -n "hello20" -r
job.batch/path-to-code-echo-hello20 created
$
$ deletejob path-to-code-echo-hello1
job.batch "path-to-code-echo-hello1" deleted
$ deletejob path-to-code-echo -p
job.batch "path-to-code-echo-hello10" deleted
job.batch "path-to-code-echo-hello20" deleted
```
