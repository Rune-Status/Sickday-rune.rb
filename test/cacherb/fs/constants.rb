module CacheRb::FS::Constants
  CACHE_COUNT = 5
  ARCHIVE_COUNT = 9
  INDEX_SIZE = 6
  HEADER_SIZE = 8
  CHUNK_SIZE = 512
  BLOCK_SIZE = HEADER_SIZE + CHUNK_SIZE
end