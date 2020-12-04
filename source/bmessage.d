module bmessage;

import std.socket : Socket, SocketFlags;

public bool receiveMessage(Socket originator, ref byte[] receiveMessage)
{
	/* Construct a buffer to receive into */
	byte[] receiveBuffer;

	/* The current byte */
	uint currentByte = 0;

	/* The amount of bytes received */
	long bytesReceived;

	/* Loop consume the next 4 bytes */
	while(currentByte < 4)
	{
		/* Temporary buffer */
		byte[4] tempBuffer;

		/* Read at-most 4 bytes */
		bytesReceived = originator.receive(tempBuffer);

		/* If there was an error reading from the socket */
		if(!(bytesReceived > 0))
		{
			/* TODO: Error handling */
			// debugPrint("Error receiving from socket");
			return false;
		}
		/* If there is no error reading from the socket */
		else
		{
			/* Add the read bytes to the *real* buffer */
			receiveBuffer ~= tempBuffer[0..bytesReceived];

			/* Increment the byte counter */
			currentByte += bytesReceived;
		}
	}

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

	/* Response message buffer */
	byte[] fullMessage;

	/* Reset the byte counter */
	currentByte = 0;

	while(currentByte < messageLength)
	{
		/**
		 * Receive 20 bytes (at most) at a time and don't dequeue from
		 * the kernel's TCP stack's buffer.
		 */
		byte[20] tempBuffer;
		bytesReceived = originator.receive(tempBuffer, SocketFlags.PEEK);

		/* Check for an error whilst receiving */
		if(!(bytesReceived > 0))
		{
			/* TODO: Error handling */
			// debugPrint("Error whilst receiving from socket");
			return false;
		}
		else
		{
			/* TODO: Make sure we only take [0, messageLength) bytes */
			if(cast(uint)bytesReceived+currentByte > messageLength)
			{
				byte[] remainingBytes;
				remainingBytes.length = messageLength-currentByte;

				/* Receive the remaining bytes */
				originator.receive(remainingBytes);

				/* Increment counter of received bytes */
				currentByte += remainingBytes.length;

				/* Append the received bytes to the FULL message buffer */
				fullMessage ~= remainingBytes;

				// writeln("Received ", currentByte, "/", cast(uint)messageLength, " bytes");
			}
			else
			{
				/* Increment counter of received bytes */
				currentByte += bytesReceived;
	
				/* Append the received bytes to the FULL message buffer */
				fullMessage ~= tempBuffer[0..bytesReceived];

				/* TODO: Bug when over send, we must not allow this */
				// writeln("Received ", currentByte, "/", cast(uint)messageLength, " bytes");	

				/* Dequeue the received bytes */
				originator.receive(tempBuffer);
			}
		}
	}

	// writeln("Message ", fullMessage);

	/* Set the message in `receiveMessage */
	receiveMessage = fullMessage;

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