module bmessage;

import std.socket : Socket, SocketFlags, MSG_WAITALL;

public bool receiveMessage(Socket originator, ref byte[] receiveMessage)
{
	/* Construct a buffer to receive into */
	byte[] receiveBuffer;

	/* Read 4 bytes of length */
	receiveBuffer.length = 4;
	originator.receive(receiveBuffer, cast(SocketFlags)MSG_WAITALL);

	/* Response message length */
	int messageLength;
	// writeln("Message length is: ", cast(uint)messageLength);

	/* Little endian version you simply read if off the bone (it's already in the correct order) */
	version(LittleEndian)
	{
		messageLength = *cast(int*)receiveBuffer.ptr;
	}

	/* Big endian requires we byte-sapped the little-endian encoded number */
	version(BigEndian)
	{
		byte[] swappedLength;
		swappedLength.length = 4;

		swappedLength[0] = receiveBuffer[3];
		swappedLength[1] = receiveBuffer[2];
		swappedLength[2] = receiveBuffer[1];
		swappedLength[3] = receiveBuffer[0];

		messageLength = *cast(int*)swappedLength.ptr;
	}

	/* Reset buffer */
	receiveBuffer.length = cast(uint)messageLength;

	/* Read the full message */
	originator.receive(receiveBuffer, cast(SocketFlags)MSG_WAITALL);

	// writeln("Message ", fullMessage);

	return true;
}

public bool sendMessage(Socket recipient, byte[] message)
{
	/* The message buffer */
	byte[] messageBuffer;

	/* Encode the 4 byte message length header (little endian) */
	int payloadLength = cast(int)message.length;
	byte* lengthBytes = cast(byte*)&payloadLength;

	/* On little endian simply get the bytes as is (it would be encoded as little endian) */
	version(LittleEndian)
	{
		messageBuffer ~= *(lengthBytes+0);
		messageBuffer ~= *(lengthBytes+1);
		messageBuffer ~= *(lengthBytes+2);
		messageBuffer ~= *(lengthBytes+3);
	}

	/* On Big Endian you must swap the big-endian-encoded number to be in little endian ordering */
	version(BigEndian)
	{
		messageBuffer ~= *(lengthBytes+3);
		messageBuffer ~= *(lengthBytes+2);
		messageBuffer ~= *(lengthBytes+1);
		messageBuffer ~= *(lengthBytes+0);
	}
	

	/* Add the message to the buffer */
	messageBuffer ~= cast(byte[])message;

	/* Send the message */
	long bytesSent = recipient.send(messageBuffer);

	/* TODO: Compact this */
	return bytesSent > 0;
}