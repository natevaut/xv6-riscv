#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  if (argint(0, &n) < 0)
    return -1;
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  if (argaddr(0, &p) < 0)
    return -1;
  return wait(p);
}

// lab7
uint64
sys_wait2(void)
{
  uint64 addr, addr1, addr2, addr3;
  uint wtime, rtime, stime;
  if (argaddr(0, &addr) < 0)
    return -1;
  if (argaddr(1, &addr1) < 0) // user virtual memory
    return -1;
  if (argaddr(2, &addr2) < 0)
    return -1;
  if (argaddr(3, &addr3) < 0)
    return -1;
  int ret = wait2(addr, &rtime, &wtime, &stime);
  struct proc *p = myproc();
  if (copyout(p->pagetable, addr1, (char *)&rtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2, (char *)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr3, (char *)&stime, sizeof(int)) < 0)
    return -1;
  return ret;
}

uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if (argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  if (argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_ps(void)
{

  ps();
  return 0;
}

uint64
sys_ps2(void)
{

  ps2();
  return 0;
}

#define PTE_A (1L << 6) // bit 6

// return err code -1 if error in func call
#define retiferr(x) \
  if (x < 0)        \
    return -1;

pte_t *walk(pagetable_t pagetable, uint64 va, int alloc); // see: vm.c

uint64
sys_pageAccess(void)
{

  uint64 usrpage_ptr; // First argument - pointer to user space address
  int npages;         // Second argument - the number of pages to examine
  uint64 useraddr;    // Third argument - pointer to the bitmap

  retiferr(argaddr(0, &usrpage_ptr));
  retiferr(argint(1, &npages));
  retiferr(argaddr(2, &useraddr));

  if (npages > 64 || npages <= 0)
    return -1;

  struct proc *p = myproc();

  // vvv
  pagetable_t pagetable = p->pagetable;

  uint64 bitmap = 0;

  for (int i = 0; i < npages; i++)
  {
    uint64 va = usrpage_ptr + i * PGSIZE; // virtual addr

    pte_t *pte = walk(pagetable, va, 0);
    if (pte == NULL)
      continue; // continue if no pte

    // see if 'page accessed' bit is set and update into bitmap
    if (*pte & PTE_A)
      bitmap |= (1 << i); // Set bit in bitmap
  }
  //^^^

  // fixup: off by one
  bitmap--;

  // Return the bitmap pointer to the user program
  retiferr(copyout(p->pagetable, useraddr, (char *)&bitmap, sizeof(bitmap)));

  return 0;
}

uint64 sys_getnice(void)
{
  int pid;

  if (argint(0, &pid) < 0)
    return -1;

  return getnice(pid);
}

uint64 sys_setnice(void)
{
  int pid, nice;

  if (argint(0, &pid) < 0 || argint(1, &nice))
    return -1;

  setnice(pid, nice);

  return 0;
}
