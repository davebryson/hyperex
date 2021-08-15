
## TODO
- Add byte_length and length to SparseBitfield
    - byte_length is total bytes
    - length is total bits: byte_length * 8  
- Add tree index.
- How are merkle and bitfield serialized to file?


## What are Genserver and deps?
Feed (depends on storage)
Storage

Supervisor.start(storage and feed)

Api:
Hyperex.append()
Hyperex.get(index)


## Memory pager notes
Provides a dynamic memory container like `ram.ex`.  The difference is Pager operates on an `index`
value vs `offset`


## Sparse Bitfield notes
 Needs to be able to 'serde' the memory's content to disk

