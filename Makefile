dev:
	nohup socat -d -d PTY,b9600 PTY,link=ttyVS1,b9600 > ./logs/socat.log &

stop:
	killall socat
