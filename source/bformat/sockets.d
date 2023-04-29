/** 
 * Socket encoding/decoding functions
 */
module bformat.sockets;

import std.socket : Socket;
import river.core;
import river.impls.sock : SockStream;

public class BClient
{
	/** 
	 * Underlying stream
	 */
	private Stream stream;

	// TODO: comment
	this(Socket socket)
	{
		this(new SockStream(socket));
	}

	// TODO: Comment
	this(Stream stream)
	{
		this.stream = stream;
	}

	/** 
	 * Receives a message from the provided socket
	 * by decoding the streamed bytes into bformat
	 * and finally placing the resulting payload in
	 * the provided array
	 *
	 * Params:
	 *   originator = the socket to receive from
	 *   receiveMessage = the nbuffer to receive into
	 *
	 * Returns: true if the receive succeeded, false otheriwse
	 */
	public bool receiveMessage(ref byte[] receiveMessage)
	{
		/* Construct a buffer to receive into */
		byte[] receiveBuffer;

		/* Get the length of the message */
		byte[4] messageLengthBytes;

		try
		{
			stream.readFully(messageLengthBytes);
		}
		catch(StreamException streamErr)
		{
			/* If there was an error reading from the socket */
			return false;
		}


		/* Response message length */
		uint messageLength;

		/* Little endian version you simply read if off the bone (it's already in the correct order) */
		version(LittleEndian)
		{
			messageLength = *cast(int*)messageLengthBytes.ptr;
		}

		/* Big endian requires we byte-sapped the little-endian encoded number */
		version(BigEndian)
		{
			byte[] swappedLength;
			swappedLength.length = 4;

			swappedLength[0] = messageLengthBytes[3];
			swappedLength[1] = messageLengthBytes[2];
			swappedLength[2] = messageLengthBytes[1];
			swappedLength[3] = messageLengthBytes[0];

			messageLength = *cast(int*)swappedLength.ptr;
		}


		/* Read the full message */
		receiveBuffer.length = messageLength;
		try
		{
			stream.readFully(receiveBuffer);
			receiveMessage = receiveBuffer;

			/* If there was no error receiving the message */
			return true;
		}
		catch(StreamException streamErr)
		{
			/* If there was an error reading from the socket */
			return false;
		}
	}

	/** 
	 * Encodes the provided message into the bformat format
	 * and sends it over the provided socket
	 *
	 * Params:
	 *   recipient = the socket to send over
	 *   message = the message to encode and send
	 *
	 * Returns: true if the send succeeded, false otherwise
	 */
	public bool sendMessage(byte[] message)
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
		long bytesSent = stream.writeFully(messageBuffer);

		/* TODO: Compact this */
		return bytesSent > 0;
	}

}







