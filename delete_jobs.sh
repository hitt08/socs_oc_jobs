if [ $# -eq 2 ] && [ $2 -eq 1 ];then
  for job in `oc get jobs | tail --lines=+2 | grep "$1" | cut -d " " -f1`;do oc delete jobs $job; done
else
  oc delete jobs $1
fi
