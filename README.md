bformat
=======

[![D](https://github.com/besterprotocol/bformat/actions/workflows/d.yml/badge.svg)](https://github.com/besterprotocol/bformat/actions/workflows/d.yml) [![Coverage Status](https://coveralls.io/repos/github/besterprotocol/bformat/badge.svg?branch=master)](https://coveralls.io/github/besterprotocol/bformat?branch=master)

A simple message format for automatically length-prefixing messages over any [`Socket`](https://dlang.org/phobos/std_socket.html#.Socket) or [River-based](https://github.com/deavmi/river) [`Stream`](https://river.dpldocs.info/river.core.stream.Stream.html).

## What is bformat?

bformat makes it easy to build applications whereby you want to send data over a streaming interface (either a `Socket` opened in `SocketType.STREAM` mode or a River-based `Stream`) and want to be able to read the data as length-prefixed messages, without the hassle of implementing this yourself. This is where bformat shines by providing support for this in a cross-platform manner so you do not have to worry about implementing it yourself countless times again every time you require such functionality in a project.

## Usage

You can see the [API](https://bformat.dpldocs.info/index.html) for information on how to use it but it boils down to spawning a new [`BClient`](https://bformat.dpldocs.info/bformat.client.BClient.html) which takes in either a `Socket` or `Stream` (see [River](https://river.dpldocs.info/river.html)) and then you can either send data using [`sendMessage(byte[])`](https://bformat.dpldocs.info/bformat.client.BClient.sendMessage.html) and receive using [`receiveMessage(ref byte[])`](https://bformat.dpldocs.info/bformat.client.BClient.receiveMessage.html).

Below we have an example application which does just this:

```d
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
}
```

### Adding to your peoject

It's rather easy to add it to your D project, just run the command `dub add bformat`.

## License

The license used is LGPL v3.
