/** 
 * Socket encoding/decoding functions
 */
module bformat.client;

import std.socket : Socket;
import river.core;
import river.impls.sock : SockStream;
import niknaks.bits : bytesToIntegral, order, Order;

/** 
 * Bformat client to encode and decode via a
 * `Socket` or river-based `Stream`
 */
public class BClient
{
	/** 
	 * Underlying stream
	 */
	private Stream stream;

	/** 
	 * Constructs a new `BClient` for encoding and decoding
	 * to and from the provided `Socket`
	 *
	 * Params:
	 *   socket = the `Socket` to use for writing and reading
	 */
	this(Socket socket)
	{
		this(new SockStream(socket));
	}

	/** 
	 * Constructs a new `BClient` for encoding and decoding
	 * to and from the provided river-based `Stream`
	 *
	 * Params:
	 *   stream = the `Stream` to use for writing and reading
	 */
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

		/* Order the bytes into Little endian (only flips if host order doesn't match LE) */
		messageLength = order(bytesToIntegral!(uint)(cast(ubyte[])messageLengthBytes), Order.LE);
		
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

		import bformat.marshall : encodeBformat;
		messageBuffer = encodeBformat(message);

		try
		{
			/* Send the message */
			stream.writeFully(messageBuffer);

			return true;
		}
		catch(StreamException streamError)
		{
			return false;
		}
	}

	/** 
	 * Closes the client
	 */
	public void close()
	{
		/* Close the underlying stream */
		stream.close();
	}
}

version(unittest)
{
	import std.socket;
	import core.thread;
	import std.stdio;
}

/**
 * Create a server that encodes a message to the client
 * and then let the client decode it from us; both making
 * use of `BClient` to accomplish this
 */
unittest
{
	UnixAddress unixAddr = new UnixAddress("/tmp/bformatServer.sock");

	scope(exit)
	{
		import std.stdio;
		remove(cast(char*)unixAddr.path());
	}

	Socket serverSocket = new Socket(AddressFamily.UNIX, SocketType.STREAM);
	serverSocket.bind(unixAddr);
	serverSocket.listen(0);

	class ServerThread : Thread
	{
		private Socket servSock;

		this(Socket servSock)
		{
			this.servSock = servSock;
			super(&worker);
		}

		private void worker()
		{
			Socket clientSock = servSock.accept();

			BClient bClient = new BClient(clientSock);

			byte[] message = cast(byte[])"ABBA";
			bClient.sendMessage(message);
		}
	}

	Thread serverThread = new ServerThread(serverSocket);
	serverThread.start();

	Socket client = new Socket(AddressFamily.UNIX, SocketType.STREAM);
	client.connect(unixAddr);
	BClient bClient = new BClient(client);

	byte[] receivedMessage;
	bClient.receiveMessage(receivedMessage);
	assert(receivedMessage == "ABBA");
	writeln(receivedMessage);
	writeln(cast(string)receivedMessage);

	bClient.close();
}