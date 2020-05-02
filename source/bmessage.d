module bmessage;

import std.socket : Socket, SocketFlags;
import std.json : JSONValue, parseJSON, toJSON;

public bool receiveMessage(Socket originator, ref JSONValue receiveMessage)
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
	int messageLength = *cast(int*)receiveBuffer.ptr;
	// writeln("Message length is: ", cast(uint)messageLength);

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
	receiveMessage = parseJSON(cast(string)fullMessage);

	return true;
}

public bool sendMessage(Socket recipient, JSONValue jsonMessage)
{
	/* The message buffer */
	byte[] messageBuffer;

	/* Get the JSON as a string */
	string message = toJSON(jsonMessage);

	/* Encode the 4 byte message length header (little endian) */
	int payloadLength = cast(int)message.length;
	byte* lengthBytes = cast(byte*)&payloadLength;
	messageBuffer ~= *(lengthBytes+0);
	messageBuffer ~= *(lengthBytes+1);
	messageBuffer ~= *(lengthBytes+2);
	messageBuffer ~= *(lengthBytes+3);

	/* Add the message to the buffer */
	messageBuffer ~= cast(byte[])message;

	/* Send the message */
	long bytesSent = recipient.send(messageBuffer);

	/* TODO: Compact this */
	return bytesSent > 0;
}