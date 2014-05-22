#fle to test the file transfer using python wave module

import wave
import socket

#Open file
audio = wave.open("receivedAudio.wav", mode='wb')
print ('opened')
#Set parameters
audio.setnchannels(1)
audio.setsampwidth(4)
audio.setframerate(16000)
audio.setnframes(0)

print('parameters set')

#read from input stream



#run server
HOST = ''                 # the local host
PORT = 2014  
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((HOST, PORT))
s.listen(1)
conn, addr = s.accept()
print ('Connected by', addr)

while 1:
    data = conn.recv(1024)
    #audio.writeframesraw(base64.b64decode(data))
    #if not data: break
    #conn.send(bytes("recieved",'UTF-8'))
conn.close()
