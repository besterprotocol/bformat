/**
 * bformat encoder/decoder
 */
module bformat;

/**
 * Encodes the provided message into the bformat format
 * and sends it over the provided socket
 */
public import bformat.sockets : sendMessage;

/**
 * Receives a message from the provided socket
 * by decoding the streamed bytes into bformat
 * and finally placing the resulting payload in
 * the provided array
 */
public import bformat.sockets : receiveMessage;

/**
 * Encodes the provided message into the bformat format
 */
public import bformat.marshall : encodeBformat;

/**
 * Decodes the provided bformat message into the
 * message itself
 */
public import bformat.marshall : decodeMessage;