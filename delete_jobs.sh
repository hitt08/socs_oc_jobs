PATTERN=0
BREAK=0
while [[ "$#" -gt 0 ]];do
    case $1 in
        -p|--pattern)
            PATTERN=1
            ;;
        -h|--help)
            BREAK=1
            echo "Usage: delete_jobs.sh <jobname or pattern string> [-p|--pattern]"
            echo "  -p, --pattern    Use pattern matching"
            ;;
        *)
            NAME=$1
            ;;
    esac
    shift
done



if [[ $BREAK -eq 0 ]];then   
    #Check if Name is set
    if [[ -z $NAME ]];then
        #NAME is required
        echo "Job Name is required. Use -h for help"
    else
        if [[ $PATTERN -eq 1 ]];then
            for job in `oc get jobs | tail --lines=+2 | grep "${NAME}" | cut -d " " -f1`;do
                oc delete jobs $job; 
            done
        else
            oc delete jobs $NAME
        fi
    fi
fi
