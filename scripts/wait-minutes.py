import os
import sys
from time import sleep

wait_time=os.getenv('OPTIONS')
sec_count=0
s="s" if int(wait_time)>1 else ""
print(f'Doing very little for {wait_time} minute{s}')
while sec_count<int(wait_time)*30:
  if sec_count%30==0:
    s="" if sec_count==30 else "s"
    print(f'\n{str(int(sec_count/30))} minute{s}')
  print(".", end="")
  sleep(2)
  sys.stdout.flush()
  sec_count+=1