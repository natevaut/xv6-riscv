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
  printf("Hello from my test case in xv6\n");

  ps();

  exit(0);
}
