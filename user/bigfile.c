// lab10
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/fs.h"

#define BIGFILE "big.file"
#define MAX (256 * 256 + 256 + 11)

int main()
{
  char buf[BSIZE];
  int fd, i, blocks;
  fd = open(BIGFILE, O_CREATE | O_WRONLY);
  if (fd < 0)
  {
    printf("bigfile: cannot open %s for writing\n", BIGFILE);
    exit(-1);
  }
  blocks = 0;
  while (1)
  {
    *(int *)buf = blocks;
    int cc = write(fd, buf, sizeof(buf));
    if (cc <= 0)
      break;
    blocks++;
    if (blocks % 100 == 0)
      printf(".");
  }
  printf("\nwrote %d blocks\n", blocks);
  if (blocks != MAX)
  {
    printf("bigfile: file is too small\n");
    exit(-1);
  }
  close(fd);
  fd = open(BIGFILE, O_RDONLY);
  if (fd < 0)
  {
    printf("bigfile: cannot re-open %s for reading\n", BIGFILE);
    exit(-1);
  }
  for (i = 0; i < blocks; i++)
  {
    int cc = read(fd, buf, sizeof(buf));
    if (cc <= 0)
    {
      printf("bigfile: read error at block %d\n", i);
      exit(-1);
    }
    if (*(int *)buf != i)
    {
      printf("bigfile: read the wrong data (%d) for block %d\n", *(int *)buf, i);
      exit(-1);
    }
  }
  printf("bigfile done; ok\n");
  exit(0);
}
