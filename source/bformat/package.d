/**
 * bformat encoder/decoder
 */
module bformat;

/**
 * Provides a client which consumes a stream
 * which can encode and decode messages to
 * and from it
 */
public import bformat.client : BClient;

/**
 * Encodes the provided message into the bformat format
 */
public import bformat.marshall : encodeBformat;

/**
 * Decodes the provided bformat message into the
 * message itself
 */
public import bformat.marshall : decodeMessage;