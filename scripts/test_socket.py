import socket

serverAddressPort = ("127.0.0.1", 4241)
bufferSize = 1024
# Create a UDP socket at client side
TCPClientSocket = socket.socket(family=socket.AF_INET, type=socket.SOCK_STREAM)
TCPClientSocket.connect(serverAddressPort)
# Send to server using created UDP socket
i = 0
while True:
    msgFromClient = f"Hello UDP Server {i}"
    bytesToSend = str.encode(msgFromClient)
    TCPClientSocket.sendall(bytesToSend)
    msgFromServer = TCPClientSocket.recv(bufferSize)
    msg = "Message from Server {}".format(msgFromServer)
    print(msg)
    i+= 1
