/**
 * Standalone encoding/decoding functions
 */
module bformat.marshall;

import niknaks.bits : toBytes, order, Order;

/** 
 * Decodes the provided bformat message into the
 * message itself
 *
 * Params:
 *   bformatBytes = the bformat payload the decode
 * Returns: the decoded message
 */
public byte[] decodeMessage(byte[] bformatBytes)
{
	/* Construct a buffer to receive into */
	byte[] receiveBuffer;

	/* Get the length of the message */
	byte[4] messageLengthBytes = bformatBytes[0..4];

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
	receiveBuffer = bformatBytes[4..4+messageLength];

	return receiveBuffer;
}

/** 
 * Encodes the provided message into the bformat format
 *
 * Params:
 *   message = the buffer containing bytes to encode
 * Returns: the encoded payload
 */
public byte[] encodeBformat(byte[] message)
{
	/* The message buffer */
	byte[] messageBuffer;

	/* Encode the 4 byte message length header (little endian) */
	messageBuffer ~= cast(byte[])toBytes(order(cast(int)message.length, Order.LE));

	/* Add the message to the buffer */
	messageBuffer ~= cast(byte[])message;

	return messageBuffer;
}

version(unittest)
{
    import std.string : cmp;
}

unittest
{
    string message = "This is my message";
    byte[] bformatEncoded = encodeBformat(cast(byte[])message);

    byte[] decodedMessageBytes = decodeMessage(bformatEncoded);
    string decodedMessage = cast(string)decodedMessageBytes;

    assert(cmp(message, decodedMessage) == 0);
}