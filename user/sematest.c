#include "kernel/types.h"
#include "user/user.h"

int main()
{
  int i, pid;

  // initialize the semaphore
  sematest(0);

  for (i = 0; i < 10; i++)
  {
    pid = fork();

    if (!pid)
      break;
  }

  if (pid)
  {
    // sleep(300);
    for (i = 0; i < 10; i++)
      wait(0);

    sematest(1);
    printf("Final %d\n", sematest(2));
  }
  else
  {
    printf("%d Down : %d\n", i, sematest(1));
    sleep(100);
    printf("%d   Up : %d\n", i, sematest(2));
  }

  exit(0);
}
