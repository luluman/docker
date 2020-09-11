timestamp=$(date +%Y-%m-%d_%H-%M-%S)
docker stats $1  --no-stream | tee --append "docker_stats_${timestamp}.txt";
sleep 1;
while true;
do docker stats $1 --no-stream | tail -n 1 | tee --append "docker_stats_${timestamp}.txt";
   sleep 1;
done
