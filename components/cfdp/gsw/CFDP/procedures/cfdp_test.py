# CFDP basic test procedure
from openc3.script import *

print("Sending CFDP NOOP...")
cmd("CFDP NOOP")
wait(2)
print("CFDP NOOP complete.")
