docker stats --no-stream | tee --append stats.txt;
sleep 1;
while true;
 do docker stats --no-stream | tail -n 1 | tee --append stats.txt; 
 sleep 1; 
done
