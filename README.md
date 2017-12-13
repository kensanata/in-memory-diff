# In Memory Diff

`in-memory-diff` takes two source buffers and treats their content as
a set of unordered lines, as one would expect for a file like
`~/.authinfo.gpg`, for example. We don't use diff(1) to diff the
buffers and thus we don't write temporary files to disk. The result is
two buffers, `*A*` and `*B*`. Each contains the lines the other buffer
does not contain. These files are in a major mode with the following
interesting keys bindings:

* `c` – copy the current line to the other source buffer
* `k` - kill the current line from this source buffer
* `RET` - visit the current line in this source buffer

In theory, using `c` and `k` on all the lines should result in the two
source containing the same lines a subsequent call of `in-memory-diff`
showing two empty buffers.
