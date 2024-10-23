#include "kernel/types.h"
#include "user/user.h"

void starttest(int count, void (*test)(int))
{
  int i, pid = 0;

  for (i = 0; i < count; i++)
  {
    pid = fork();
    if (!pid)
      break;
  }

  if (pid)
  {
    for (i = 0; i < count; i++)
      wait(0);
  }
  else
  {
    test(i);
    exit(0);
  }
}

void readlocktest(int time)
{
  int r;
  r = rwsematest(1);
  printf("RD %d\n", r);
  sleep(time);
  r = rwsematest(2);
  printf("RU %d\n", r);
  sleep(time);
}

void writelocktest(int i, int time)
{
  rwsematest(3);
  printf("%d DW\n", i);
  sleep(time);
  rwsematest(4);
  printf("%d UW\n", i);
}

void test1(int i)
{
  //  readlocktest(0);
  readlocktest((i + 1) * 10);
}

void test2(int i)
{
  sleep((5 - i) * 10);
  writelocktest(i, (i + 2) * 10);
}

void test3(int i)
{
  switch (i)
  {
  case 0:
    sleep(10);
    writelocktest(i, 50);
    break;
  case 1:
  case 2:
    sleep(25 + i * 10);
  case 3:
  case 4:
    readlocktest(50 + i * 10);
  }
}

int main()
{
  // initialize the semaphore
  rwsematest(0);

  printf("\nread lock test\n");
  starttest(5, test1);
  printf("\nwrite lock test\n");
  starttest(5, test2);

  printf("\nread & write lock test\n");
  starttest(5, test3);

  exit(0);
}
