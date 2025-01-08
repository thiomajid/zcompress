# zcompress

`zcompress` is a command line tool that offers various compression algorithms for files. It allows you to compress and decompress files using different algorithms to suit your needs.

## Features

- Supports multiple compression algorithms
- Easy to use command line interface
- Fast and efficient compression and decompression

## Supported Algorithms

- RLE
- Huffman encoding
- LZ77

## Installation

To install `zcompress`, clone the repository and build the project:

```sh
git clone https://github.com/yourusername/zcompress.git
cd zcompress
make
```

## Usage

To compress a file:

```sh
zcompress -a <algorithm> -c <input_file> -o <output_file>
```

To decompress a file:

```sh
zcompress -a <algorithm> -d <input_file> -o <output_file>
```

## Examples

Compress a file using gzip:

```sh
zcompress -a gzip -c example.txt -o example.txt.gz
```

Decompress a file using gzip:

```sh
zcompress -a gzip -d example.txt.gz -o example.txt
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on GitHub.

## License

This project is licensed under the MIT License.