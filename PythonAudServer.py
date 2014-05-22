# Echo server program
import socket
import wave
import time

CHUNK = 1024
CHANNELS = 1
RATE = 16000
WAVE_OUTPUT_FILENAME = "receivedAudio.wav"
frames = []



HOST = ''                 # local host
PORT = 1234
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((HOST, PORT))

wf = wave.open(WAVE_OUTPUT_FILENAME, mode='wb')
wf.setnchannels(CHANNELS)
wf.setsampwidth(2)
wf.setframerate(RATE)

s.listen(1)
conn, addr = s.accept()
print ('Connected by', addr)
data = conn.recv(1024)
i=1
#while True:
while i<100: #MOSHKELA HENA
    i=i+1
    data = conn.recv(1024)
    if data != '':
        print(i)
        frames.append(data)

wf.writeframes(b''.join(frames))
#wf.writeframes(frames)
wf.close()

#start listening again
'''wf = wave.open(WAVE_OUTPUT_FILENAME, mode='wb')
wf.setnchannels(CHANNELS)
wf.setsampwidth(2)
wf.setframerate(RATE)
    
i = 1
s.listen(1)
conn, addr = s.accept()
print ('Connected by', addr)
data = conn.recv(1) #1024'''
    
#write frames to file

   

conn.close()
s.close()
