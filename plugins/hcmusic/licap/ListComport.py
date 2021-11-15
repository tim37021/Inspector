import serial.tools.list_ports

ports = serial.tools.list_ports.comports()

for port, desc, hwid in sorted(ports):
    print("{}: {} [{}]".format(port, desc, hwid))
    if "VID:PID=0483:5740" in hwid:
        print(port)