# gzip.sh
gzip compression/decompression in Bash, for the patient

### What's this?

Enough crypto play, here comes an [RFC 1951](https://datatracker.ietf.org/doc/html/rfc1951)/[RFC 1952](https://datatracker.ietf.org/doc/html/rfc1952)-compliant, extremely inefficient and slow implementation of a [**`gzip`**](https://en.wikipedia.org/wiki/Gzip) ([also](https://www.gnu.org/software/gzip/)) compressor/decompressor without any external programs. No dependencies, other than a recent version of bash.

**WARNING: THIS IS EXTREMELY SLOW AND INEFFICIENT. DO NOT USE IT FOR ANY SERIOUS PURPOSE, AND DO NOT USE IT ON LARGE AMOUNTS OF DATA (EVEN _A FEW TENS_ OF KB ARE ALREADY A LOT FOR THIS BEAST). YOU HAVE BEEN WARNED.**

### Why is it "low speed"?

See the following comparison with `gzip` to compress a file:

```
$ ls -l /bin/w
-rwxr-xr-x 1 root root 22572 Apr  6 09:17 /bin/w
$ time gzip < /bin/w > /dev/null

real    0m0.004s
user    0m0.004s
sys     0m0.000s
$ time ./gzip.sh < /bin/w > /dev/null

real    0m10.743s
user    0m10.646s
sys     0m0.083s
```

### How do I install it?

Just run the `gzip.sh` script with the necessary arguments (see **`gzip.sh -h`** for help).

### How do I use it with `tar`?

You really don't want to do that, but if you feel like it you can use it as follows (with GNU tar at least):

```
# create a tar file
tar -cvf archive.tgz --use-compress-program=/path/to/gzip.sh [FILE...]
# extract from tar file
tar -xvf archive.tgz --use-compress-program=/path/to/gzip.sh [MEMBER...]
```

### How well does `gzip.sh` compress?

The parsing algorithm is homebrew, so in general compressed sizes are slightly larger than `gzip` (sometimes more than just "slightly"). Here's a table with some numbers (for `gzip`'s and `gzip.sh`'s default compression settings, and for `gzip.sh`'s maximum compression):

| file                  | original | `gzip` | `gzip.sh` | `gzip.sh -c 9` |
|-----------------------|---------:|--------------:|---------------------------:|--:|
| `calgary_bib`        | 111261         |  35059           |  36533   | 36428  |
| `calgary_obj1`      |  21504        | 10318           |  10474           | 10474 |
| `x_seq` (_see note_) |       78894           | 34418            | 27600  |  27631  |
| `cantrbry_asyoulik.txt` | 125179 | 48938 | 50409 | 50252 |
| `artificl_alphabet.txt` | 100000 | 302 | 316 | 316 |

_Note_: `x_seq` (you can find it in `tests/files`, it's just the output of `seq 1 15000`) is a peculiar corner case, for which both `gzip` and `gzip.sh` do not exhibit expected behavior when the compression level is increased; in fact, the compressed size mostly _increases_ with the compression level; see the following table:

| level | `gzip -<level>` | `gzip.sh -c <level>` |
|---|--------:|-------------:|
|1  | 29669   | 26366|
|2  |26801    | 26901|
|3  |27440    | 27205|
|4  |34163    | 27496|
|5  |34368    | 27600|
|6  |34418    | 27631|
|7  |34418    | 27631|
|8  |34418    | 27631|
|9  |34418    | 27631|

Still, _for this particular file_, `gzip.sh` performs better (compression-wise only, of course) than `gzip` on average and best/worst case (not really anything to be proud of; just a simple curiosity).
Full results for all files with all compression types and levels are available in the file `results.txt`.

### How do I know that it produces correct results?

Change to the `tests/` directory and run `run.sh` (be prepared to wait for some time). It will perform various tests, including compressing files with `gzip` and decompressing them with `gzip.sh`, and viceversa (for `gzip.sh`'s various compression types and levels). By default, there are a few sample files under `files/`, if you want more data just run the `download_extra_files.sh` script which will download additional files from the [Canterbury corpora](https://corpus.canterbury.ac.nz/descriptions/) (which include the Calgary corpus as well). All tests should pass.
If you only want to run with some specific file/compression type/compression level, there are switches to control that (see `run.sh -h`).

### Why should I use gzip.sh?

You should NOT and you must NOT use `gzip.sh` for anything.

### Internals

To keep things simple, the DEFLATE block type (stored, fixed Huffman, dynamic Huffman) is statically set when the program is launched and is not modified throughout the compression process. I believe real tools use heuristics to dynamically decide which block type to emit at runtime.
The compression code reads chunks of data from stdin (by default 65535 bytes at a time); each chunk is turned into an output DEFLATE block.
To keep track of matches, a series of hash chains are employed, one for each 3-character (or minlen-characters) combination; each chain contains the match positions for the key within the buffer window, from the most recent to the oldest. The naive parsing algorithm checks for the next 3 chars in the input, and walks back the chain for that key looking for the longest match until it's either gone back "enough" or has found a match long "enough". How much "enough" is depends on the chosen compression level: the highest the level, the further back in the chain the matcher is allowed to go, and the longer a match should be to be considered satisfactory (and the slower the code, of course, though it's slow anyway). The values for "enough back" and "enough long" for each level are (mostly) arbitrary and hardcoded in the script.
Yes, it's naive.

When the block format is 1 (fixed Huffman codes), compressed data is output directly while the input is parsed, since the codes are known in advance; when the block format is 2 (dynamic Huffman codes), the input is parsed and stored in an intermediate form while also computing symbol frequencies, then the Huffman codes are computed based on the frequencies, and finally the intermediate form is read from the beginning and the actual compressed data is written to stdout.

### References

- DEFLATE Compressed Data Format Specification, RFC 1951: https://datatracker.ietf.org/doc/html/rfc1951
- GZIP file format specification, RFC 1952: https://datatracker.ietf.org/doc/html/rfc1952
- Infgen (invaluable tool to check that what you're emitting is correct): https://github.com/madler/infgen
- Dissecting the GZIP format: https://commandlinefanatic.com/cgi-bin/showarticle.cgi?article=art001
- A completely dissected GZIP file: https://commandlinefanatic.com/cgi-bin/showarticle.cgi?article=art053
- Length-limited prefix codes summary, implementation and and explanation of existing techniques (the algorithm used by `gzip.sh` is taken from there): https://create.stephan-brumme.com/length-limited-prefix-codes/

