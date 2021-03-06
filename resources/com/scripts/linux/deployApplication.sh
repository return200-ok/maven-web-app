parseFile(){
    grep -w $1 jobScript.map | awk '{print $2}' | head -n1
}

verify_image_match () {
    a=false
    image_require=$(grep -w $1 jobScript.map | awk '{print $3}')
    for image in $image_require
    do
        if [[ $2 == *"$image"* ]];then
            a=true
        fi
    done
    if $a;then
        return 0
    else 
        return 1
    fi
}

deployApplication(){
    jobname=$1
    image_version=$2
    deployEnviroment=$3
    deployment_file=$(parseFile $jobname)
    if $(verify_image_match $jobname $image_version); then
        echo "Unlock the deployment"
        sed -ie "s/THIS_STRING_IS_REPLACED_DURING_BUILD/$(date)/g" ${deployment_file} # verify your job with current date
        echo "Reconfig image version"
        sed -ie "s|IMAGE_VERSION|${image_version}|g" ${deployment_file}
        case $deployEnviroment in 
            "k8s")
                echo "Deploying application to k8s"
                kubectl apply -f ${deployment_file}
            ;;
            "swarm")
                echo "Deploying application to swarm"
                docker stack deploy --compose-file ${deployment_file} --with-registry-auth $stackName
            ;;
            *)
                echo "Please check your deploy enviroment"
            ;;
        esac
    else
        echo "Fail to deploy, please check your image!"
    fi
}

deployApplication $1 $2 $3