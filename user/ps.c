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
  int paramc = argc - 1; // because argc includes the command name
  // if no args given: run the default ps (all)
  if (paramc == 0)
  {
    ps();
  }
  // if one argument given ('ps -r'): run ps2 (only 'running')
  else
  {
    char arg = argv[1][1]; // char[1] of first arg after the cmd name : `ps -r` -> 'r'
    if (arg == 'r')
    {
      ps2();
    }
    // only argument available is -r, so anything else fails
    else
    {
      printf("Wrong command option.\n");
    }
  }

  exit(0);
}
