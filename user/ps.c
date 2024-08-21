#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#include "kernel/param.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"
#include "kernel/spinlock.h"
#include "kernel/proc.h"

int main(int argc, char *argv[])
{
  if (argc == 1)
  {
    ps();
  }
  else
  {
    char arg = argv[1][1]; // char[1] of first arg after the cmd name (e.g. ps -r -> r)
    if (arg == 'r')
    {
      ps2();
    }
    else
    {
      printf("Wrong command option.");
    }
  }

  exit(0);
}
